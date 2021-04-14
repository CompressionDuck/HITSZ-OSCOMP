#!/bin/bash
#author:ldq

declare -i counter=1
declare -i lineh
declare -i linet
lineh=0
linet=0
while true; do
	sudo dmesg > meg
	grep -e "zram-page:" meg > megt
	linet=$(cat "megt" | wc -l )
    if [[ $lineh == $linet ]];then
        sleep 1
        continue
    fi
    lineh=$((lineh+1))
    
    for num in $(sed -n ''$lineh',$p' megt|awk '{print $4}' );do
        if [[ "$counter" -lt 4 ]]; then 
            counter=$((counter+1))
            printf "%s\t" $num >> result
        else
            counter=1
            printf "%s\n" $num >> result
        fi

    done

    lineh=$linet
    sleep 1
done