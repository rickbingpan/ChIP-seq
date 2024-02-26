#!/bin/bash

if [ $# != 3 ]
then
	echo -ne "sh $0 <out_path> <sample> <yes|no>"
	exit 1
fi
##sh /mnt/sda/Public/Project/EZH2/training/bing.pan/ChIPseq/ESRRB_nature/pipeline/02_map_dm6.sh /mnt/sda/Public/Project/EZH2/training/bing.pan/ChIPseq/ESRRB_nature/ SRR26145813 yes

outdir=$1
sample=$2
pair=$3
pipeline=`dirname $0`

ref=/mnt/sda/Public/Database/Drosophila_melanogaster/
chip=/mnt/sda/Public/Environment/miniconda3/envs/ChIP/bin


mkdir -p $outdir/02_map_dm6/$sample
cd $outdir/02_map_dm6/$sample

##MAP
if [ $pair == "yes" ]
then
	${chip}/bowtie2 --threads 12 -x $ref/dm6 -1 $outdir/01_qc_map/$sample/${sample}_1_val_1.fq.gz -2 $outdir/01_qc_map/$sample/${sample}_2_val_2.fq.gz | ${chip}/samtools view -@ 12 -Sbh - > ${sample}.bam
else
	${chip}/bowtie2 --threads 12 -x $ref/dm6 -U $outdir/01_qc_map/$sample/${sample}_trimmed.fq.gz | ${chip}/samtools view -@ 12 -Sbh - > ${sample}.bam
fi
${chip}/samtools sort -@ 12 ${sample}.bam > ${sample}.sorted.bam
${chip}/picard MarkDuplicates INPUT=./${sample}.sorted.bam OUTPUT=./${sample}.rmdup.bam METRICS_FILE=./${sample}.metrics VALIDATION_STRINGENCY=SILENT ASSUME_SORTED=true REMOVE_DUPLICATES=false

if [ $pair == "yes" ]
then
	${chip}/samtools view -@ 12 -q 10 -F1804 -1 ./${sample}.rmdup.bam > ./${sample}.final.bam
else
	${chip}/samtools view -@ 12 -q 10 -F1024 -1 ./${sample}.rmdup.bam > ./${sample}.final.bam
fi
${chip}/samtools index -@ 12 ${sample}.final.bam
${chip}/bam_stat.py -q 10 -i ${sample}.final.bam 1>assessment.sh.o 2>assessment.sh.e




