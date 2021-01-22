/*-
 * Copyright 2003-2005 Colin Percival
 * Copyright 2012 Matthew Endsley
 * All rights reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted providing that the following conditions 
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "bsdiff.h"
#include <stdio.h>
#define DEBUG 1
#include <limits.h>
#include <string.h>

#define MIN(x, y) (((x) < (y)) ? (x) : (y))

static void split(int64_t *I, int64_t *V, int64_t start, int64_t len, int64_t h)
{
	int64_t i, j, k, x, tmp, jj, kk;

	if (len < 16)
	{
		for (k = start; k < start + len; k += j)
		{
			j = 1;
			x = V[I[k] + h];
			for (i = 1; k + i < start + len; i++)
			{
				if (V[I[k + i] + h] < x)
				{
					x = V[I[k + i] + h];
					j = 0;
				};
				if (V[I[k + i] + h] == x)
				{
					tmp = I[k + j];
					I[k + j] = I[k + i];
					I[k + i] = tmp;
					j++;
				};
			};
			for (i = 0; i < j; i++)
				V[I[k + i]] = k + j - 1;
			if (j == 1)
				I[k] = -1;
		};
		return;
	};

	x = V[I[start + len / 2] + h];
	jj = 0;
	kk = 0;
	for (i = start; i < start + len; i++)
	{
		if (V[I[i] + h] < x)
			jj++;
		if (V[I[i] + h] == x)
			kk++;
	};
	jj += start;
	kk += jj;

	i = start;
	j = 0;
	k = 0;
	while (i < jj)
	{
		if (V[I[i] + h] < x)
		{
			i++;
		}
		else if (V[I[i] + h] == x)
		{
			tmp = I[i];
			I[i] = I[jj + j];
			I[jj + j] = tmp;
			j++;
		}
		else
		{
			tmp = I[i];
			I[i] = I[kk + k];
			I[kk + k] = tmp;
			k++;
		};
	};

	while (jj + j < kk)
	{
		if (V[I[jj + j] + h] == x)
		{
			j++;
		}
		else
		{
			tmp = I[jj + j];
			I[jj + j] = I[kk + k];
			I[kk + k] = tmp;
			k++;
		};
	};

	if (jj > start)
		split(I, V, start, jj - start, h);

	for (i = 0; i < kk - jj; i++)
		V[I[jj + i]] = kk - 1;
	if (jj == kk - 1)
		I[jj] = -1;

	if (start + len > kk)
		split(I, V, kk, start + len - kk, h);
}

static void qsufsort(int64_t *I, int64_t *V, const uint8_t *old, int64_t oldsize)
{
	int64_t buckets[256];
	int64_t i, h, len;

	for (i = 0; i < 256; i++)
		buckets[i] = 0;
	for (i = 0; i < oldsize; i++)
		buckets[old[i]]++;
	for (i = 1; i < 256; i++)
		buckets[i] += buckets[i - 1];
	for (i = 255; i > 0; i--)
		buckets[i] = buckets[i - 1];
	buckets[0] = 0;

	for (i = 0; i < oldsize; i++)
		I[++buckets[old[i]]] = i;
	I[0] = oldsize;
	for (i = 0; i < oldsize; i++)
		V[i] = buckets[old[i]];
	V[oldsize] = 0;
	for (i = 1; i < 256; i++)
		if (buckets[i] == buckets[i - 1] + 1)
			I[buckets[i]] = -1;
	I[0] = -1;

	for (h = 1; I[0] != -(oldsize + 1); h += h)
	{
		len = 0;
		for (i = 0; i < oldsize + 1;)
		{
			if (I[i] < 0)
			{
				len -= I[i];
				i -= I[i];
			}
			else
			{
				if (len)
					I[i - len] = -len;
				len = V[I[i]] + 1 - i;
				split(I, V, i, len, h);
				i += len;
				len = 0;
			};
		};
		if (len)
			I[i - len] = -len;
	};

	for (i = 0; i < oldsize + 1; i++)
		I[V[i]] = i;
}

static int64_t matchlen(const uint8_t *old, int64_t oldsize, const uint8_t *new, int64_t newsize)
{
	int64_t i;

	for (i = 0; (i < oldsize) && (i < newsize); i++)
		if (old[i] != new[i])
			break;

	return i;
}

static int64_t search(const int64_t *I, const uint8_t *old, int64_t oldsize,
					  const uint8_t *new, int64_t newsize, int64_t st, int64_t en, int64_t *pos)
{
	int64_t x, y;

	if (en - st < 2)
	{
		x = matchlen(old + I[st], oldsize - I[st], new, newsize);
		y = matchlen(old + I[en], oldsize - I[en], new, newsize);

		if (x > y)
		{
			*pos = I[st];
			return x;
		}
		else
		{
			*pos = I[en];
			return y;
		}
	};

	x = st + (en - st) / 2;
	if (memcmp(old + I[x], new, MIN(oldsize - I[x], newsize)) < 0)
	{
		return search(I, old, oldsize, new, newsize, x, en, pos);
	}
	else
	{
		return search(I, old, oldsize, new, newsize, st, x, pos);
	};
}

static void offtout(int64_t x, uint8_t *buf)
{
	int64_t y;

	if (x < 0)
		y = -x;
	else
		y = x;

	buf[0] = y % 256;
	y -= buf[0];
	y = y / 256;
	buf[1] = y % 256;
	y -= buf[1];
	y = y / 256;
	buf[2] = y % 256;
	y -= buf[2];
	y = y / 256;
	buf[3] = y % 256;
	y -= buf[3];
	y = y / 256;
	buf[4] = y % 256;
	y -= buf[4];
	y = y / 256;
	buf[5] = y % 256;
	y -= buf[5];
	y = y / 256;
	buf[6] = y % 256;
	y -= buf[6];
	y = y / 256;
	buf[7] = y % 256;

	if (x < 0)
		buf[7] |= 0x80;
}

static int64_t writedata(struct bsdiff_stream *stream, const void *buffer, int64_t length)
{
	int64_t result = 0;

	while (length > 0)
	{
		const int smallsize = (int)MIN(length, INT_MAX);
		const int writeresult = stream->write(stream, buffer, smallsize);
		if (writeresult == -1)
		{
			return -1;
		}

		result += writeresult;
		length -= smallsize;
		buffer = (uint8_t *)buffer + smallsize;
	}

	return result;
}

struct bsdiff_request
{
	const uint8_t *old;
	int64_t oldsize;
	const uint8_t *new;
	int64_t newsize;
	struct bsdiff_stream *stream;
	int64_t *I;
	uint8_t *buffer;
};

static int bsdiff_internal(const struct bsdiff_request req)
{
	// I: 已经排好的字典序
	int64_t *I, *V;
	int64_t scan, pos, len;
	// lastoffset: lastoffset为new和old的偏移量,如果在old中的内容A在new中可以找到，
	// 			   而且A+lastoffset=new中的A，则认为old和new中的A相同。
	int64_t lastscan, lastpos, lastoffset;
	// oldscore代表相同内容的len
	// scsc代表new中开始和old中比较是否相同开始的位置
	int64_t oldscore, scsc;
	// 而old中开始的位置是scsc+lastoffset。lenf代表扩展前缀，lenb代表扩展后缀。
	int64_t s, Sf, lenf, Sb, lenb;
	int64_t overlap, Ss, lens;
	int64_t i;
	uint8_t *buffer;
	uint8_t buf[8 * 3];

	if ((V = req.stream->malloc((req.oldsize + 1) * sizeof(int64_t))) == NULL)
		return -1;
	I = req.I;
	// 任务1：生成后缀数组
	qsufsort(I, V, req.old, req.oldsize);
#if DEBUG == 1
	printf("old size = %ld\nold string:  ", req.oldsize);
	for(int i = 0;i<req.oldsize;i++){
		printf("%c", req.old[i]);
	}
	printf("\nold string:  ");
	for(int i = 0;i<req.oldsize;i++){
		printf("%d", i%10);
	}
	printf("\n");

	printf("new size = %ld\nnew string:  ", req.newsize);
	for(int i = 0;i<req.newsize;i++){
		printf("%c", req.new[i]);
	}
	printf("\n");
	for(int k = 0; k <= req.oldsize; k++){
		printf("%ld ", I[k]);
	}
	printf("\n");
#endif
	req.stream->free(V);

	buffer = req.buffer;

	/* Compute the differences, writing ctrl as we go */
    // scan: new中要查询的字符
	scan = 0;
    // len: 匹配的长度
	len = 0;
    // pos: 代表old中相匹配的字符
	pos = 0;
	lastscan = 0;
	lastpos = 0;
	lastoffset = 0;
    // 任务2：循环处理新文件数据，找到代码操作导致二进制数据相差字节多于 8bytes 的偏移点
	while (scan < req.newsize)
	{
		oldscore = 0;
		int count = 0;
		for (scsc = scan += len; scan < req.newsize; scan++)
		{
            // 新版本文件和老版本文件都从数据开头开始，通过二分法，在整个后缀数组 I 中找到与新版本数据匹配最长的长度 len 和数组编号 pos。
            // 返回的数组编号即为在老版本文件中的偏移。
			len = search(I, req.old, req.oldsize, req.new + scan, 
                         req.newsize - scan, 0, req.oldsize, &pos);
#if DEBUG == 1
			printf("%d: len = %ld, scan = %ld, pos = %ld, scsc = %ld, req.newsize = %ld",count++,len,scan,pos, scsc, req.newsize);
#endif
			// 计算出当前偏移的 old 数据与 new 数据相同的字节个数，再与 len 比较
			for (; scsc < scan + len; scsc++)
				if ((scsc + lastoffset < req.oldsize) &&
					(req.old[scsc + lastoffset] == req.new[scsc]))
					oldscore++;
#if DEBUG == 1
			printf(", oldscore = %ld\n",oldscore);
#endif
			// 如果相差小于 8 则继续 for 循环。
            // 相差小于 8，可以认为插入的数据较少，没必要切换 old 数据的 offset，每切换一次就需要进行一次 diff 和 extra 处理。
			if (((len == oldscore) && (len != 0)) ||
				(len > oldscore + 8))
				break;

			if ((scan + lastoffset < req.oldsize) &&
				(req.old[scan + lastoffset] == req.new[scan]))
				oldscore--;
		};
		// 对上一个位置到新位置之间的数据进行处理
		if ((len != oldscore) || (scan == req.newsize))
		{
			s = 0;
			Sf = 0;
			lenf = 0;
            // 计算 diff string 的长度
			for (i = 0; (lastscan + i < scan) && (lastpos + i < req.oldsize);)
			{
				if (req.old[lastpos + i] == req.new[lastscan + i])
					s++;
				i++;

                // 由于任务2中找的是差异较大的点，因此差异较大的部分就是该段数据的末尾数据，从头开始比较，通过以下判断可以近似找出类似的最长字符串。
                /** Sf*2-lenf 和 s*2-i 都是等式： a*2 - b。
* Sf*2-lenf可以理解为 上一组s和i，s*2-i计算出的值。
* s*2 - i, i和s的增长步长都为1，也就是i走两步，s走一步就可以维持s*2 - i结果不变，
如果结果要增加，也就是s增加的频率要>50%，即后续增加的数据超过50%的数据需要是相等的。*/
				if (s * 2 - i > Sf * 2 - lenf)
				{
					Sf = s;
					lenf = i;
				};
			};
			// 获取与下一段数据近似相同数据的长度
			lenb = 0;
			if (scan < req.newsize)
			{
				s = 0;
				Sb = 0;
				for (i = 1; (scan >= lastscan + i) && (pos >= i); i++)
				{
					if (req.old[pos - i] == req.new[scan - i])
						s++;
					if (s * 2 - i > Sb * 2 - lenb)
					{
						Sb = s;
						lenb = i;
					};
				};
			};
            /* 上面lenf的值即为diff string的长度，该段数据剩余部分即可认为是extra string，
            这样长度相减即可获得extra string的长度;但是保存的diff string是新老数据的相差值，
            可以更好的被压缩，而extra string保存的就是原始数据，压缩层度不高，
            为了减少extea string的长度，采取了将部分extra string与下一段数据近似相同的数据遗留下来，
            在下一段数据可以充当diff string。
            scan等于newsize，就没有下一段数据了，因此这里需要判断scan小于newsize。
            */
            
			// 上面两段数据可能重叠，处理重叠
			if (lastscan + lenf > scan - lenb)
			{
				overlap = (lastscan + lenf) - (scan - lenb);
				s = 0;
				Ss = 0;
				lens = 0;
				for (i = 0; i < overlap; i++)
				{
					if (req.new[lastscan + lenf - overlap + i] ==
						req.old[lastpos + lenf - overlap + i])
						s++;
					if (req.new[scan - lenb + i] ==
						req.old[pos - lenb + i])
						s--;
					if (s > Ss)
					{
						Ss = s;
						lens = i + 1;
					};
				};

				lenf += lens - overlap;
				lenb -= lens;
			};
			// 如果上面两段数据存在重叠，说明不存在extra string，重叠部分可以划分给当前diff string，也可以划分给下一段diff string，这里根据相似数据分布获取到lens值。
			offtout(lenf, buf);
			offtout((scan - lenb) - (lastscan + lenf), buf + 8);
			offtout((pos - lenb) - (lastpos + lenf), buf + 16);

			/* Write control data */
			if (writedata(req.stream, buf, sizeof(buf)))
				return -1;

			/* Write diff data */
			for (i = 0; i < lenf; i++)
				buffer[i] = req.new[lastscan + i] - req.old[lastpos + i];
			if (writedata(req.stream, buffer, lenf))
				return -1;

			/* Write extra data */
			for (i = 0; i < (scan - lenb) - (lastscan + lenf); i++)
				buffer[i] = req.new[lastscan + lenf + i];
			if (writedata(req.stream, buffer, (scan - lenb) - (lastscan + lenf)))
				return -1;
			// 保存偏移
			lastscan = scan - lenb;
			lastpos = pos - lenb;
			lastoffset = pos - scan;
            /*
            lenf值即为diff string的长度；
            (scan-lenb)-(lastscan+lenf)即为extra string的长度。
            diff string保存的是相差值，可以很好被压缩。
            */
		};
	};

	return 0;
}

int bsdiff(const uint8_t *old, int64_t oldsize, const uint8_t *new, int64_t newsize, struct bsdiff_stream *stream)
{
	int result;
	struct bsdiff_request req;

	if ((req.I = stream->malloc((oldsize + 1) * sizeof(int64_t))) == NULL)
		return -1;

	if ((req.buffer = stream->malloc(newsize + 1)) == NULL)
	{
		stream->free(req.I);
		return -1;
	}

	req.old = old;
	req.oldsize = oldsize;
	req.new = new;
	req.newsize = newsize;
	req.stream = stream;

	result = bsdiff_internal(req);

	stream->free(req.buffer);
	stream->free(req.I);

	return result;
}
#define BSDIFF_EXECUTABLE 1
#if defined(BSDIFF_EXECUTABLE)

#include <sys/types.h>

#include <bzlib.h>
#include <err.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static int bz2_write(struct bsdiff_stream *stream, const void *buffer, int size)
{
	int bz2err;
	BZFILE *bz2;

	bz2 = (BZFILE *)stream->opaque;
	BZ2_bzWrite(&bz2err, bz2, (void *)buffer, size);
	if (bz2err != BZ_STREAM_END && bz2err != BZ_OK)
		return -1;

	return 0;
}

int main(int argc, char *argv[])
{
	int fd;
	int bz2err;
	uint8_t *old, *new;
	off_t oldsize, newsize;
	uint8_t buf[8];
	FILE *pf;
	struct bsdiff_stream stream;
	BZFILE *bz2;

	memset(&bz2, 0, sizeof(bz2));
	stream.malloc = malloc;
	stream.free = free;
	stream.write = bz2_write;

	if (argc != 4)
		errx(1, "usage: %s oldfile newfile patchfile\n", argv[0]);

	/* Allocate oldsize+1 bytes instead of oldsize bytes to ensure
		that we never try to malloc(0) and get a NULL pointer */
	if (((fd = open(argv[1], O_RDONLY, 0)) < 0) ||
		((oldsize = lseek(fd, 0, SEEK_END)) == -1) ||
		((old = malloc(oldsize + 1)) == NULL) ||
		(lseek(fd, 0, SEEK_SET) != 0) ||
		(read(fd, old, oldsize) != oldsize) ||
		(close(fd) == -1))
		err(1, "%s", argv[1]);

	/* Allocate newsize+1 bytes instead of newsize bytes to ensure
		that we never try to malloc(0) and get a NULL pointer */
	if (((fd = open(argv[2], O_RDONLY, 0)) < 0) ||
		((newsize = lseek(fd, 0, SEEK_END)) == -1) ||
		((new = malloc(newsize + 1)) == NULL) ||
		(lseek(fd, 0, SEEK_SET) != 0) ||
		(read(fd, new, newsize) != newsize) ||
		(close(fd) == -1))
		err(1, "%s", argv[2]);

	/* Create the patch file */
	if ((pf = fopen(argv[3], "w")) == NULL)
		err(1, "%s", argv[3]);

	/* Write header (signature+newsize)*/
	offtout(newsize, buf);
	if (fwrite("ENDSLEY/BSDIFF43", 16, 1, pf) != 1 ||
		fwrite(buf, sizeof(buf), 1, pf) != 1)
		err(1, "Failed to write header");

	if (NULL == (bz2 = BZ2_bzWriteOpen(&bz2err, pf, 9, 0, 0)))
		errx(1, "BZ2_bzWriteOpen, bz2err=%d", bz2err);

	stream.opaque = bz2;
	if (bsdiff(old, oldsize, new, newsize, &stream))
		err(1, "bsdiff");

	BZ2_bzWriteClose(&bz2err, bz2, 0, NULL, NULL);
	if (bz2err != BZ_OK)
		err(1, "BZ2_bzWriteClose, bz2err=%d", bz2err);

	if (fclose(pf))
		err(1, "fclose");

	/* Free the memory we used */
	free(old);
	free(new);

	return 0;
}

#endif
