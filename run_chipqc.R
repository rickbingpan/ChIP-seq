#source("https://raw.githubusercontent.com/ThomasCarroll/blank/master/chipqcAnnotation.R")
#/mnt/sda/Public/Environment/miniconda3/envs/R_common/bin/R
library(ChIPQC)
library(GenomicRanges)
library(GenomicFeatures)

#samples <- read.csv('test.csv')
#btaurus_txdb <- makeTxDbFromGFF('/mnt/sda/Public/Database/GRCm38_release_100/Mus_musculus.GRCm38.100.chr.gtf.gz')
#mm_anno <- ChIPQCAnnotationFromGFF3('/mnt/sda/Public/Database/GRCm38_release_100/Mus_musculus.GRCm38.100.chr.gtf.gz') 

samples <- read.csv('chipqc_input.csv')
chipObj <- ChIPQC(samples, annotation="mm10", blacklist = NULL) 

#options(browser="firefox")
#utils::browseURL("http://google.com/")

ChIPQCreport(chipObj, reportName="test", reportFolder="ChIPQCreport")


######result summary
#awk -F' ' '{print $1"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10}' ChIPQC_manual_result.txt |grep -v "Reads" > ChIPQC.result
#sed -i '1i\sample\tChIPQC_ReadL\tChIPQC_FragL\tChIPQC_RelCC\tChIPQC_SSD\tChIPQC_RiP%' ChIPQC.result


