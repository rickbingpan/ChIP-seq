#!/bin/bash

if [ $# != 1 ]
then
	echo -ne "sh $0"
	exit 1
	##----------------callpeak.sample.info file format------------------
	##treatment1	control1	heat_name1
	##treatment2	control2	heat_name2
fi

projectdir=$1
cd $projectdir
for i in `awk -F'_' '{print $1"_"$2}' callpeak.sample.info |uniq`
do
	awk -F'\t' '{if($7>5&&$8>9){print $1"\t"$2"\t"$3}}' 03_call_peak/${i}*/*_peaks.narrowPeak |bedtools sort -i - |bedtools merge -d 1 -i - > 03_call_peak/${i}_overlap1.peaks
done

###filter blacklist
#blacklist=/mnt/sda/Public/Database/Blacklist/mm10-blacklist.v2.bed
#bedtools intersect -v -a $peak -b ${blacklist} > filter_black.peak
