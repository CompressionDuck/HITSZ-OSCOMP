#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "./disk.c"
#define EXT2_BLOCK_SIZE 1024
#define TYPE_FILE 0
#define TYPE_DIR 1
//656B 用一个块保存
typedef struct super_block
{
    int32_t magic_num;        // 幻数
    int32_t free_block_count; // 空闲数据块数
    int32_t free_inode_count; // 空闲inode数
    int32_t dir_inode_count;  // 目录inode数
    uint32_t block_map[128];  // 数据块占用位图
    uint32_t inode_map[32];   // inode占用位图
} sp_block;

//32B 每32个inode保存在一个块
typedef struct inode
{
    //表示用了多少个block   不表示文件大小
    uint32_t size;           // 文件大小
    uint16_t file_type;      // 文件类型（文件/文件夹）
    uint16_t link;           // 连接数
    uint32_t block_point[6]; // 数据块指针
} inode;

//128B 一个block可以放8个
typedef struct dir_item
{                      // 目录项一个更常见的叫法是 dirent(directory entry)
    uint32_t inode_id; // 当前目录项表示的文件/目录的对应inode
    uint16_t valid;    // 当前目录项是否有效
    uint8_t type;      // 当前目录项类型（文件/目录）
    char name[121];    // 目录项表示的文件/目录的文件名/目录名
} dir_item;


/*
    读block
    输入块号block_num（系统），缓存buf
        由于物理块大小为512B，系统块大小为1024B
        所以需要调用2次 int disk_read_block(unsigned int block_num, char* buf)
*/
void readBlock(unsigned int block_num, char *buf){
    disk_read_block(block_num*2,buf);
    disk_read_block(block_num*2+1,buf+DEVICE_BLOCK_SIZE);
}

/*
    写block
    同 void readBlock(unsigned int block_num, char *buf)
*/
void writeBlock(unsigned int block_num, char *buf){
    disk_write_block(block_num*2,buf);
    disk_write_block(block_num*2+1,buf+DEVICE_BLOCK_SIZE);
}

/*
    读超级块
        超级块的块号为0
        将读出的char[1024]以char*的方式拷贝给spBlock
*/
void readSuperBlock(sp_block *spBlock){
    char buf[EXT2_BLOCK_SIZE];
    //超级块的块号为0
    readBlock(0,buf);
    char *p = (char*)spBlock;
    for(int i=0;i<sizeof(sp_block);i++){
        p[i] = buf[i];
    }
}

/*
    写超级块
        同 void readSuperBlock(sp_block *spBlock)
*/
void writeSuperBlock(sp_block *spBlock){
    char buf[EXT2_BLOCK_SIZE];
    char *p = (char*)spBlock;
    for(int i=0;i<sizeof(sp_block);i++){
        buf[i]=p[i];
    }
    writeBlock(0,buf);
}

/*
    读取inodeTable
        一个inode 32B
        一共1024个inode
        所以需要32个块存储inode_table
        而第0个块为超级块
*/
void readInodeTable(inode* inode_table){
    char buf[1024];
    char *p=(char*)inode_table;
    for(int i=1;i<33;i++){
        readBlock(i,buf);
        for(int j=0;j<1024;j++){
            p[j]=buf[j];
        }
    }
}

/*
    写inodeTable
    同void readInodeTable(inode* inode_table)
*/
void writeInodeTable(inode* inode_table){
    char buf[1024];
    char *p=(char*)inode_table;
    for(int i=1;i<33;i++){
        for(int j=0;j<1024;j++){
            buf[j]=p[j];
        }
        writeBlock(i,buf);
    }
}

/*
    找到可用的inode
    返回找到的第一个空闲块，并修改超级块
        可以用<<和&进行判断inode是否被使用
    如果没有找到，返回-1
*/
int findFreeInode(){
    int num = -1;
    sp_block *spBlock = (sp_block *)malloc(sizeof(sp_block));
    readSuperBlock(spBlock);
    for(int i=0;i<32;i++){
        for(int j=0;j<32;j++){
            //      k表示只有第j位为1的32位整数，其他为0
            uint32_t k = 1 << (31-j);

            //printf("pBlock->inode_map[i]:%u\n",spBlock->inode_map[i]);
            //printf("k:%u\n",k);
            //printf("spBlock->inode_map[i] & k:%u\n",spBlock->inode_map[i] & k);

            //      如果该这个inode被使用了，跳过
            if((spBlock->inode_map[i] & k) == k){
                //printf("跳过\n");
                continue;
            }
            num = i*32 + j;
            spBlock->inode_map[i] = spBlock->inode_map[i] | (1 << (31-j));
            spBlock->free_inode_count--;
            writeSuperBlock(spBlock);
            return num;
        }
    }
    return num;
}

/*
    找到可用Block
    返回找到的第一个空闲块，并修改超级块
        逻辑同int findFreeInode()
    如果没有找到，返回-1
*/
int findFreeBlock(){
    int num = -1;
    sp_block *spBlock = (sp_block *)malloc(sizeof(sp_block));
    readSuperBlock(spBlock);
    for(int i=0;i<128;i++){
        for(int j=0;j<32;j++){
            int k = 1 << (31-j);
            if((spBlock->block_map[i] & k) == k){
                continue;
            }
            num = i*32 + j;
            spBlock->block_map[i] = spBlock->block_map[i] | (1 << (31-j));
            spBlock->free_block_count--;
            writeSuperBlock(spBlock);
            return num;
        }
    }
    return num;
}

/*
    EXT2系统初始化
*/
void ext2Init(){
    sp_block *spBlock = (sp_block*)malloc(sizeof(sp_block));
    inode inodeTable[1024];
    dir_item rootDirItem[8];
    open_disk();
    readSuperBlock(spBlock);

    if(spBlock->magic_num!=0xdec0de){
        //初始化
        printf("初始化\n");
        spBlock->magic_num=0xdec0de;

        //1:根目录
        spBlock->dir_inode_count=1;
        //32：存放inode表，1：存放superBlock,1:分配给根目录
        spBlock->free_block_count=4096-32-1-1;
        //1:根目录
        spBlock->free_inode_count=1024-1;

        //初始化block和inode map
        memset(spBlock->block_map,0,sizeof(spBlock->block_map));
        memset(spBlock->inode_map,0,sizeof(spBlock->inode_map));
        //uint32第32位（高位）表示第0个block/inode，第0位（低位）表示第31个block/inode
        spBlock->inode_map[0]=(1<<31);
        spBlock->block_map[0]=~(spBlock->block_map[0]);
        spBlock->block_map[1]=(1<<31) | (1<<30);

        //初始化根目录
        memset(inodeTable,0,sizeof(inodeTable));
        inodeTable[0].block_point[0]=33;
        inodeTable[0].file_type = TYPE_DIR;
        inodeTable[0].size=1;
        //初始化根目录的目录项
        memset(rootDirItem,0,sizeof(rootDirItem));

        writeBlock(33,(char*)rootDirItem);
        writeInodeTable(inodeTable);
        writeSuperBlock(spBlock);
    }
}

/*
    通过path找到对应的inode
        迭代寻找
        从根目录开始寻找
        如/abc/def
        从根目录查找，找到name为abc的文件夹，
        再查找abc下名字为def的文件夹
    返回inode号
*/
int findInode(char* path){
    //printf("path长度为：%ld\n",strlen(path));
    if(strlen(path)<=1)
        return 0;
    //本次迭代寻找的结果，找到了为1，否则为0
    int flag = 0;
    inode inodeTable[1024];
    int inodeNum = 0;
    int len = strlen(path);
    readInodeTable(inodeTable);
    dir_item dir_items[8];
    char name[121];
    int begin = 1;
    for(int end = 0;end<=len;end++){
        //找到'/'或者path结束时进行一次迭代
        if(end > 0 && path[end]=='/' || end == len){
            memset(name,0,sizeof(name));
            strncpy(name,path+begin,end-begin);
            begin = end+1;
            //每个inode指向6个block
            for(int i = 0;i<6;i++){
                flag = 0;
                memset(dir_items,0,sizeof(dir_items));
                readBlock(inodeTable[inodeNum].block_point[i],(char*)dir_items);
                //每个block有8个dir_item
                for(int j=0;j<8;j++){
                    if(dir_items[j].valid==0)
                        continue;
                    if(strcmp(name,dir_items[j].name)==0){
                        //下一轮迭代的inodeNum
                        inodeNum=dir_items[j].inode_id;
                        flag = 1;
                        break;
                    }
                }
                if(flag==1)
                    break;
            }
        }
    }
    return inodeNum;
}

/*
    创建文件夹
    输入格式 mkdir /abc 在根目录下建立abc文件夹
            mkdir /a/abc 在跟目录的a目录下建立abc文件夹
*/
int mkdir(char* path){
    //读inode表
    inode inodeTable[1024];
    readInodeTable(inodeTable);
    int len = strlen(path);
    dir_item dir_items[8];
    //找到空闲inode
    int freeInode = findFreeInode();
    //修改inode
    inodeTable[freeInode].file_type = TYPE_FILE;
    char nameBuf[121],pathBuf[200];
    memset(nameBuf,0,sizeof(nameBuf));
    memset(pathBuf,0,sizeof(nameBuf));
    //该文件所在的目录inode号
    int fatherInode = 0;
    //获得name 和path
    for(int i=len-1;i>=0;i--){
        if(path[i]=='/' || i==0){
            strncpy(nameBuf,path+i+1,len-i-1);
            strncpy(pathBuf,path,i);
            //printf("path:%s %ld\n",pathBuf,strlen(pathBuf));
            //printf("name:%s\n",nameBuf);
            break;
        }
    }
    //strlen(pathBuf)<=1表示为根目录
    if(strlen(pathBuf)>1){
        fatherInode = findInode(pathBuf);
        //printf("fatherInode为%d\n不是根目录\n",fatherInode);
    }
        
    //在已使用的block中寻找
    for(int i=0;i<inodeTable[fatherInode].size;i++){
        memset(dir_items,0,sizeof(dir_items));
        readBlock(inodeTable[fatherInode].block_point[i],(char*)dir_items);
        //读该block的8个dir_item
        for(int j=0;j<8;j++){
            //找到可用的
            if(dir_items[j].valid==0){
                dir_items[j].valid=1;
                dir_items[j].type=TYPE_DIR;
                dir_items[j].inode_id=freeInode;
                strcpy(dir_items[j].name,nameBuf);
                //printf("块号：%d   分配的inode为%d\n",inodeTable[fatherInode].block_point[i],dir_items[j].inode_id);
                writeBlock(inodeTable[fatherInode].block_point[i],(char*)dir_items);
                writeInodeTable(inodeTable);
                //printf("不需要新分配块\n");
                return freeInode;
            }
        }
    }
    //如果已使用的block没有找到空余空间
    //分配一个新的block给目录
    //printf("需要新分配块\n");
    int size = ++inodeTable[fatherInode].size;
    inodeTable[fatherInode].block_point[size-1] = findFreeBlock();
    //printf("块号：%d   分配的inode为%d\n",inodeTable[fatherInode].block_point[size-1],inodeTable[fatherInode].block_point[size-1]);
    writeInodeTable(inodeTable);
    memset(dir_items,0,sizeof(dir_items));
    dir_items[0].valid=1;
    dir_items[0].inode_id=freeInode;
    dir_items[0].type=TYPE_DIR;
    strcpy(dir_items[0].name,nameBuf);
    writeBlock(inodeTable[fatherInode].block_point[size-1],(char*)dir_items);
    return freeInode;
}

/*
    创建文件
    输入格式 touch /abc 在根目录下建立abc文件
            touch /a/abc 在跟目录的a目录下建立abc文件
*/
int touch(char* path){
    //读inode表
    inode inodeTable[1024];
    readInodeTable(inodeTable);
    int len = strlen(path);
    dir_item dir_items[8];
    //找到空闲inode
    int freeInode = findFreeInode();
    //修改inode
    inodeTable[freeInode].file_type = TYPE_FILE;
    char nameBuf[121],pathBuf[200];
    memset(nameBuf,0,sizeof(nameBuf));
    memset(pathBuf,0,sizeof(nameBuf));
    //该文件所在的目录inode号
    int fatherInode = 0;
    //获得name 和path
    for(int i=len-1;i>=0;i--){
        if(path[i]=='/' || i==0){
            strncpy(nameBuf,path+i+1,len-i-1);
            strncpy(pathBuf,path,i);
            break;
        }
    }
    //strlen(pathBuf)<=1表示为根目录
    if(strlen(pathBuf)>1)
        fatherInode = findInode(pathBuf);
    //在已使用的block中寻找
    for(int i=0;i<inodeTable[fatherInode].size;i++){
        memset(dir_items,0,sizeof(dir_items));
        readBlock(inodeTable[fatherInode].block_point[i],(char*)dir_items);
        //读该block的8个dir_item
        for(int j=0;j<8;j++){
            //找到可用的
            if(dir_items[j].valid==0){
                dir_items[j].valid=1;
                dir_items[j].type=TYPE_FILE;
                dir_items[j].inode_id=freeInode;
                strcpy(dir_items[j].name,nameBuf);
                writeBlock(inodeTable[fatherInode].block_point[i],(char*)dir_items);
                writeInodeTable(inodeTable);
                return freeInode;
            }
        }
    }
    //如果已使用的block没有找到空余空间
    //分配一个新的block给目录
    int size = ++inodeTable[fatherInode].size;
    inodeTable[fatherInode].block_point[size-1] = findFreeBlock();
    writeInodeTable(inodeTable);
    memset(dir_items,0,sizeof(dir_items));
    dir_items[0].valid=1;
    dir_items[0].inode_id=freeInode;
    dir_items[0].type=TYPE_FILE;
    strcpy(dir_items[0].name,nameBuf);
    writeBlock(inodeTable[fatherInode].block_point[size-1],(char*)dir_items);
    return freeInode;
}

