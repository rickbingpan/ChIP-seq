#!/usr/bin/env Rscript
##------------------------/home/bing.pan/software/miniconda3/bin/R
##------------------------ AI merge 3 fig and optimize
library(ggplot2)
library(pheatmap)
args <- commandArgs(T)
InFile <- args[1]
InFile1 <- args[2]
name <- args[3]

data=read.table(InFile, head=T, row.names = 1, sep="\t")
pdf(paste(name,".model.heatmap.pdf",sep=""))
pheatmap(data, show_colnames = T, show_rownames = F, cluster_rows = F, cluster_cols = F,
	cellheight=15, cellwidth=15,
	color = colorRampPalette(c('white','#011e8a'))(50), border=F, angle_col = 90, fontsize_col=10,
	legend_breaks=0:1, legend=T, legend_labels=c("0","1"))
dev.off()

data1 = read.table(InFile1, head=T, sep="\t", row.names=1)
genomeD = data.frame(data1[1:15,1]/100)
colnames(genomeD) = "genome"

pdf(paste(name,".genome.heatmap.pdf",sep=""))
pheatmap(genomeD, show_colnames = T, show_rownames = F, cluster_rows = F, cluster_cols = F,
	cellheight=15, cellwidth=30,
	display_numbers = TRUE,number_format = "%.2f",
	color = colorRampPalette(c('white','#011e8a'))(50), border=F, angle_col = 90, fontsize_col=10,
	legend_breaks=0:1, legend=T, legend_labels=c("0","1"))
dev.off()


olD = data.frame(data1[1:15,2:7])
colnames(olD) = c("ARID1A", "BRD9","EZH2","Rpb1","SUZ12","TBP")
#olD = olD/max(olD)
#olD <- apply(olD, 2, function(x) if (0 %in% x) x else x/max(x))
olD <- apply(olD, 2, function(x) x/max(x))
olD

pdf(paste(name,".overlap.heatmap.pdf",sep=""))
pheatmap(olD, show_colnames = T, show_rownames = F, cluster_rows = F, cluster_cols = F,
	cellheight=15, cellwidth=15,
	color = colorRampPalette(c('white','#ccd6fc','#011e8a'))(90), border=F, angle_col = 90, fontsize_col=10,
	legend_breaks=0:1, legend=T, legend_labels=c("0","1"))
dev.off()


