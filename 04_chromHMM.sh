#!/bin/bash

if [ $# != 2 ]
then
	echo -ne "sh $0 <project_path> <ref>"
	exit 1
fi

projectdir=$1
ref=$2
gsize=`awk -F'\t' '{sum+=$2}END{print sum}' $ref/*fai`
pipeline=`dirname $0`
#gsize=2.8e9
#ref=/mnt/sda/Public/Database/GRCm38_release_100
chip=/mnt/sda/Public/Environment/ChIP/bin/

mkdir -p $projectdir/04_chromHMM/histron_bam
ln -s $projectdir/01_qc_map/*/*.final.bam* $projectdir/04_chromHMM/histron_bam

##1、prepare chromHMM.HM.txt file
#------asyn	H3K27ac	asyn_H3K27ac_rep1.final.bam	asyn_input_rep1.final.bam
#------mit	H3K27ac	mit_H3K27ac_rep1.final.bam	mit_input_rep1.final.bam
##2、prepare chromhmm.reorder.hmnames.txt
#------H3K4me3
#------H3K27ac

cd $projectdir/04_chromHMM/
##BinarizeBam
java -Xmx48g -jar /mnt/sda/Public/Environment/ChromHMM/ChromHMM.jar BinarizeBam -paired -strictthresh -t ./out_signal $ref/*.fai ./histron_bam/ ./chromHMM.HM.txt ./out_binary

##optional, set signalthresh parameter, we filter 1/4 score, 3 in here.
#java -Xmx48g -jar /mnt/sda/Public/Environment/ChromHMM/ChromHMM.jar BinarizeSignal -g 3 ./out_signal ./out_binary_g3

##LearnModel, chromsome state (8~25) can set, 15 in here.
java -Xmx48g -jar /mnt/sda/Public/Environment/ChromHMM/ChromHMM.jar LearnModel -l $ref/*.fai -p 64 ./out_binary "learnmodel.15" 15 mm10

##reorder chromsome state, edit chromhmm.reorder.states.txt file
java -Xmx8g -jar /mnt/sda/Public/Environment/ChromHMM/ChromHMM.jar reorder -f ./chromhmm.reorder.hmnames.txt -o ./chromhmm.reorder.states.txt learnmodel.15/model_15.txt chromhmm.reorder

##analysis other data by trained model
java -Xmx8g -jar /mnt/sda/Public/Environment/ChromHMM/ChromHMM.jar MakeSegmentation chromhmm.reorder/model_15.txt out1 chromhmm.reorder

##OverlapEnrichment
java -Xmx8g -jar /mnt/sda/Public/Environment/ChromHMM/ChromHMM.jar OverlapEnrichment -uniformscale chromhmm.reorder/asyn_15_segments.bed test_ansy chromhmm.reorder/test
java -Xmx8g -jar /mnt/sda/Public/Environment/ChromHMM/ChromHMM.jar OverlapEnrichment chromhmm.reorder/asyn_15_segments.bed test_ansy chromhmm.reorder/test


#################################plot heatmap by R.------------------ prepare emissions_15.txt and asyn_ol.txt files
Rscript post_trim_heatmap.R emissions_15.txt asyn_ol.txt asyn_ol
