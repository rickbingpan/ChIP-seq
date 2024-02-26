#!/bin/bash

if [ $# != 6 ]
then
	echo -ne "sh $0 <project_path> <tre> <con> <paire> <ref> <blacklist.bed>"
	exit 1
	##----------------callpeak.sample.info file format------------------
	##treatment1	control1
	##treatment2	control2
fi

projectdir=$1
tre=$2
con=$3
paire=$4
pipeline=`dirname $0`
ref=$5
blacklist=$6
gsize=`awk -F'\t' '{sum+=$2}END{print sum}' $ref/*fai`

#ref=/mnt/sda/Public/Database/GRCm38_release_100
#blacklist=/mnt/sda/Public/Database/Blacklist/mm10-blacklist.v2.bed
chip=/mnt/sda/Public/Environment/miniconda3/envs/ChIP/bin

export PATH="/mnt/sda/Public/Environment/miniconda3/envs/ChIP/bin/:$PATH"
mkdir -p $projectdir/03_call_peak/${tre}-VS-${con}
cd $projectdir/03_call_peak/${tre}-VS-${con}

if [ $paire == "yes" ]
then
	###call peak narrowPeak
	${chip}/macs2 callpeak -g $gsize -f BAMPE -t ${projectdir}/01_qc_map/${tre}/${tre}.final.bam -c ${projectdir}/01_qc_map/${con}/${con}.final.bam -n $tre-VS-$con --outdir ./ &> ./${tre}-VS-${con}.log
	bedtools intersect -v -a ${tre}-VS-${con}_peaks.narrowPeak -b ${blacklist} > ${tre}-VS-${con}_peaks.narrowPeak.FB
	awk -F'\t' '{if($7>5&&$8>9){print $1"\t"$2"\t"$3}}' ${tre}-VS-${con}_peaks.narrowPeak.FB > ${tre}-VS-${con}_peaks.narrowPeak.FB.hash.peak	

        ###call peak broadPeak
	mkdir -p $projectdir/03_call_peak/${tre}-VS-${con}_broad
	cd $projectdir/03_call_peak/${tre}-VS-${con}_broad
	${chip}/macs2 callpeak --broad -g $gsize -f BAMPE -t ${projectdir}/01_qc_map/${tre}/${tre}.final.bam -c ${projectdir}/01_qc_map/${con}/${con}.final.bam -n $tre-VS-$con --outdir ./ &> ./${tre}-VS-${con}.log
	bedtools intersect -v -a ${tre}-VS-${con}_peaks.broadPeak -b ${blacklist} > ${tre}-VS-${con}_peaks.broadPeak.FB
	awk -F'\t' '{if($7>5&&$8>9){print $1"\t"$2"\t"$3}}' ${tre}-VS-${con}_peaks.broadPeak.FB > ${tre}-VS-${con}_peaks.broadPeak.FB.hash.peak
else
	${chip}/macs2 callpeak -g $gsize -t ${projectdir}/01_qc_map/${tre}/${tre}.final.bam -c ${projectdir}/01_qc_map/${con}/${con}.final.bam -n $tre-VS-$con --outdir ./ &> ./${tre}-VS-${con}.log
	bedtools intersect -v -a ${tre}-VS-${con}_peaks.narrowPeak -b ${blacklist} > ${tre}-VS-${con}_peaks.narrowPeak.FB
	awk -F'\t' '{if($7>5&&$8>9){print $1"\t"$2"\t"$3}}' ${tre}-VS-${con}_peaks.narrowPeak.FB > ${tre}-VS-${con}_peaks.narrowPeak.FB.hash.peak
	
	mkdir -p $projectdir/03_call_peak/${tre}-VS-${con}_broad
	cd $projectdir/03_call_peak/${tre}-VS-${con}_broad
	${chip}/macs2 callpeak --broad -g $gsize -t ${projectdir}/01_qc_map/${tre}/${tre}.final.bam -c ${projectdir}/01_qc_map/${con}/${con}.final.bam -n $tre-VS-$con --outdir ./ &> ./${tre}-VS-${con}.log
	bedtools intersect -v -a ${tre}-VS-${con}_peaks.broadPeak -b ${blacklist} > ${tre}-VS-${con}_peaks.broadPeak.FB
	awk -F'\t' '{if($7>5&&$8>9){print $1"\t"$2"\t"$3}}' ${tre}-VS-${con}_peaks.broadPeak.FB > ${tre}-VS-${con}_peaks.broadPeak.FB.hash.peak

fi
