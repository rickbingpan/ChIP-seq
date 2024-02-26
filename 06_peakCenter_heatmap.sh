#!/bin/bash
###################---------note: first complete bw files, then to plot heatmap.----------manual---------------

if [ $# != 3 ]
then
	echo -ne "sh $0 <project_path> <peak> <sample>"
	exit 1
fi

project=$1
peak=$2
sample=$3

ChIP=/mnt/sda/Public/Environment/miniconda3/envs/ChIP/bin

mkdir -p $project/05_disHeatmap
#################################################------------------------------then------------------------######################
######plot peaks center heatmap
#raw
$ChIP/computeMatrix reference-point -R $peak -S ${sample}.bw --beforeRegionStartLength 3000 --afterRegionStartLength 3000 -bs 50 -p 48 --referencePoint center --outFileName ${sample}.mat.raw.gz
$ChIP/plotHeatmap -m ${sample}.mat.raw.gz --outFileName ${sample}.hm.raw.pdf --colorMap magma --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''
$ChIP/plotHeatmap -m ${sample}.mat.raw.gz --outFileName ${sample}.hm.raw.red.pdf --colorMap Reds --missingDataColor '#FDEEE7' --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''
$ChIP/plotHeatmap -m ${sample}.mat.raw.gz --outFileName ${sample}.hm.raw.blue.pdf --colorMap Blues --missingDataColor '#EEF3F9' --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''
#rpm
$ChIP/computeMatrix reference-point -R $peak -S ${sample}.rpm.bw --beforeRegionStartLength 3000 --afterRegionStartLength 3000 -bs 50 -p 48 --referencePoint center --outFileName ${sample}.mat.rpm.gz
$ChIP/plotHeatmap -m ${sample}.mat.rpm.gz --outFileName ${sample}.hm.rpm.pdf --colorMap magma --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''
$ChIP/plotHeatmap -m ${sample}.mat.rpm.gz --outFileName ${sample}.hm.rpm.red.pdf --colorMap Reds --missingDataColor '#FDEEE7' --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''
$ChIP/plotHeatmap -m ${sample}.mat.rpm.gz --outFileName ${sample}.hm.rpm.blue.pdf --colorMap Blues --missingDataColor '#EEF3F9' --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''

#spiker IN
$ChIP/computeMatrix reference-point -R $peak -S ${sample}.bw --beforeRegionStartLength 3000 --afterRegionStartLength 3000 -bs 50 -p 48 --referencePoint center --outFileName ${sample}.mat.min.gz
$ChIP/plotHeatmap -m ${sample}.mat.min.gz --outFileName ${sample}.hm.min.pdf --colorMap magma --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''
$ChIP/plotHeatmap -m ${sample}.mat.min.gz --outFileName ${sample}.hm.min.pdf --colorMap Reds --missingDataColor '#FDEEE7' --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''
$ChIP/plotHeatmap -m ${sample}.mat.min.gz --outFileName ${sample}.hm.min.pdf --colorMap Blues --missingDataColor '#EEF3F9' --heatmapHeight 11 --heatmapWidth 2 --yMin 0 --yMax 3 --dpi 600 --samplesLabel ${sample} --xAxisLabel '' --refPointLabel ''

