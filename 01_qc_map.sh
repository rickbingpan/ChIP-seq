#!/bin/bash
##################################prepare rawdata and ref.fa.fai

if [ $# != 5 ]
then
	echo -ne "sh $0 <rawdata_path> <out_path> <sample> <yes|no> <ref>"
	exit 1
fi
##sh /mnt/sda/Public/Project/EZH2/training/bing.pan/ChIPseq/ESRRB_nature/pipeline/01_qc_map.sh /mnt/sda/Public/Rawdata_download/ESRRB_rawdata_nature/ /mnt/sda/Public/Project/EZH2/training/bing.pan/ChIPseq/ESRRB_nature/ SRR26145813 yes

rawdatadir=$1
outdir=$2
sample=$3
pair=$4
pipeline=`dirname $0`
ref=$5    #/mnt/sda/Public/Database/GRCm38_release_100/mm10.fa
gsize=`awk -F'\t' '{sum+=$2}END{print sum}' ${ref}.fai`
#gsize=2.8e9
#ref=/mnt/sda/Public/Database/GRCm38_release_100/
chip=/mnt/sda/Public/Environment/miniconda3/envs/ChIP/bin/

export PATH="/mnt/sda/Public/Environment/miniconda3/envs/ChIP/bin/:$PATH"

mkdir -p $outdir/01_qc_map/$sample
cd $outdir/01_qc_map/$sample
	
##QC
if [ $pair == "yes" ]
then
	#${chip}/fastp -i $rawdatadir/${sample}_1.fastq.gz -I $rawdatadir/${sample}_2.fastq.gz -o ${sample}_clean.R1.fq.gz -O ${sample}_clean.R2.fq.gz -q 20 -w 12 -l 25 -j ./${sample}.fastp.json -h ./${sample}.fastp.html
	${chip}/trim_galore --cores 8 --paired --fastqc --gzip $rawdatadir/${sample}_1.fastq.gz $rawdatadir/${sample}_2.fastq.gz -o ./
else
	#${chip}/fastp -i $rawdatadir/${sample}.fastq.gz -o ${sample}_clean.R1.fq.gz -q 20 -w 12 -l 25 -j ./${sample}.fastp.json -h ./${sample}.fastp.html
	${chip}/trim_galore --cores 8 --fastqc --gzip $rawdatadir/${sample}.fastq.gz -o ./
fi
#python $pipeline/q30_plot.py ${sample}.fastp.json $sample


##MAP
if [ $pair == "yes" ]
then
	${chip}/bowtie2 --threads 12 -x $ref -1 ${sample}_1_val_1.fq.gz -2 ${sample}_2_val_2.fq.gz | ${chip}/samtools view -@ 12 -Sbh - > ${sample}.bam
	#'--local --very-sensitive-local --no-unal --no-mixed --no-discordant --phred33 -I 10 -X 700' for cut&run
else
	${chip}/bowtie2 --threads 12 -x $ref -U ${sample}_trimmed.fq.gz | ${chip}/samtools view -@ 12 -Sbh - > ${sample}.bam
fi
${chip}/samtools sort -@ 12 ${sample}.bam > ${sample}.sorted.bam
${chip}/picard MarkDuplicates INPUT=./${sample}.sorted.bam OUTPUT=./${sample}.rmdup.bam METRICS_FILE=./${sample}.metrics VALIDATION_STRINGENCY=SILENT ASSUME_SORTED=true REMOVE_DUPLICATES=false
${chip}/samtools index -@ 12 ${sample}.rmdup.bam
${chip}/bam_stat.py -q 10 -i ${sample}.rmdup.bam 1>assessment.sh.o 2>assessment.sh.e

if [ $pair == "yes" ]
then
	${chip}/samtools view -@ 12 -q 10 -F1804 -1 ./${sample}.rmdup.bam > ./${sample}.final.bam
else
	${chip}/samtools view -@ 12 -q 10 -F1024 -1 ./${sample}.rmdup.bam > ./${sample}.final.bam
fi
${chip}/samtools index -@ 12 ${sample}.final.bam
${chip}/bam_stat.py -q 10 -i ${sample}.final.bam 1>f.assessment.sh.o 2>f.assessment.sh.e

bedtools bamtobed -i ${sample}.final.bam > ${sample}.bed
bedtools genomecov -i ${sample}.bed -g ${ref}.fai -bg > ${sample}.bedgraph
sort -k1,1 -k2,2n ${sample}.bedgraph > ${sample}.sorted.bedgraph
/mnt/sda/Public/Environment/bedGraphToBigWig ${sample}.sorted.bedgraph ${ref}.fai ${sample}.bw
rm -rf *.bedgraph *.sorted.bam ${sample}.bam
