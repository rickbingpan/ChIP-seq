#!/bin/bash
if [ $# != 4 ]
then
	echo -ne "sh $0 <sample> <min_spike> <projectdir> <fai>"
	exit 1
fi



sample=$1
min_spike=$2  #map dm6, min Total records
projectdir=$3
ref=$4
#ref=/mnt/sda/Public/Database/GRCm38_release_100/mm10.fa.fai

export PATH="/mnt/sda/Public/Environment/miniconda3/envs/ChIP/bin/:$PATH"
cd $projectdir/01_qc_map/$sample
rpm=`grep "Total records" ./f.assessment.sh.o |sed 's/ //g'|awk -F':' '{print $2}'`
sf1=`echo "10000000 / $rpm" | bc -l`
rpm_spike=`grep "Total records" ../../02_map_dm6/$sample/assessment.sh.o |sed 's/ //g'|awk -F':' '{print $2}'`
sf2=`echo "$min_spike / $rpm_spike" | bc -l`
sf=`echo "$sf1 * $sf2" | bc -l`

#######1 RPM
bedtools genomecov -scale $sf1 -i ${sample}.bed -g $ref -bg > ${sample}.rpm.bedgraph
sort -k1,1 -k2,2n ${sample}.rpm.bedgraph > ${sample}.sorted.rpm.bedgraph
/mnt/sda/Public/Environment/bedGraphToBigWig ${sample}.sorted.rpm.bedgraph $ref ${sample}.rpm.bw

#######2 RPM and spkieIN(min/mapped reads)
bedtools genomecov -scale $sf -i ${sample}.bed -g $ref -bg > ${sample}.min.bedgraph
sort -k1,1 -k2,2n ${sample}.min.bedgraph > ${sample}.sorted.min.bedgraph
/mnt/sda/Public/Environment/bedGraphToBigWig ${sample}.sorted.min.bedgraph $ref ${sample}.min.bw

rm -rf *bedgraph

