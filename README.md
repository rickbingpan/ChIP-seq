# Introduction
ChIP-Seq pipeline is a bioinformatics analysis pipeline used for Chromatin ImmunopreciPitation sequencing (ChIP-Seq) data.

The rawdata for the pipeline testing is histone and transcription factor IP experiments from ([GEO: GSE189563](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE189563)).

The pipeline is designed to process QC, mapping, calling peak, ChIPQC, chromHMM for ChIP-Seq data. 
overview of ChIP-Seq pipeline:

![peak pipeline](https://github.com/rickbingpan/ChIP-seq/assets/92712179/47ae80d5-bfa5-4953-895f-d3f541a67050)
# Installation
- Installed software packages: [`TrimGalore`](https://github.com/FelixKrueger/TrimGalore), [`bowtie2`](https://bowtie-bio.sourceforge.net/bowtie2/index.shtml), [`samtools`](http://www.htslib.org/), [`picard`](https://broadinstitute.github.io/picard/), [`RSeQC`](https://rseqc.sourceforge.net/), [`bedtools`](https://bedtools.readthedocs.io/en/latest/), [`deeptools`](https://deeptools.readthedocs.io/en/develop/), [`ChromHMM`](https://compbio.mit.edu/ChromHMM/) and [`macs2`](https://hbctraining.github.io/Intro-to-ChIPseq/lessons/05_peak_calling_macs.html).

# Prepare data
1. FASTQ rawdata
2. Reference genome index files for mapping
3. sample.list: It contains 1 column, `sample`.
4. call.peak.info: It contains 2 columns, `treatment(IP sample) , control(INPUT sample)`.
5. chromHMM.HM.txt: It contains 4 columns, such as `asyn      H3K27ac      asyn_H3K27ac_rep1.final.bam      asyn_input_rep1.final.bam`
6. chromhmm.reorder.hmnames.txt: It contains a Histone name every row, such as</br>
      `H3K4me3`</br>
      `H3K27ac`</br>
      `...`
7. chromhmm.reorder.states.txt: It contains 2 colomuns, `raw state      reorder state(start from 1)`

# Pipeline summary
## 01_qc_map.sh

Quality control (QC) and mapping of the ChIP-Seq data. the following parameters:

```bash
sh 01_qc_map.sh <rawdata_path> <out_path> <sample> <yes|no> <ref>
```

- `rawdata_path`: The path to the directory containing the raw data files.
- `out_path`: Current working directory.
- `sample`: The name of the ChIP-Seq sample.
- `yes|no`: Whether the data is paired-end (`yes`) or single-end (`no`).
- `ref`: The reference genome file index, such as hg38.fa.

The script performs the following steps:

1. Quality Control:  [`TrimGalore`](https://github.com/FelixKrueger/TrimGalore) are used to assess and trim raw sequencing data, ensuring high-quality reads for mapping.
2. Read Mapping: clean reads are aligned to the reference genome using [`bowtie2`](https://bowtie-bio.sourceforge.net/bowtie2/index.shtml).
3. Marking Duplicates: [`picard`](https://broadinstitute.github.io/picard/) are used to mark potential PCR duplicates in the aligned reads.
4. Filtering: Depending on whether the data is paired-end (`-q 10 -F1804`) or single-end (`-q 10 -F1024`), the script uses [`samtools`](http://www.htslib.org/) to filter the aligned reads based on mapping quality and flags. The filtered reads are stored in a file named `<sample>.final.bam`.
5. Result Conversion to BigWig: The final BAM files are converted into BED format, and then into bedgraph format, followed by conversion to BigWig format using [bedGraphToBigWig](https://www.encodeproject.org/software/bedgraphtobigwig/) for visualization ([`IGV`](https://www.igv.org/)).
6. Additional analysis: Statistical mapping information (`assessment.sh.o` for rmdup.bam map results , `assessment.sh.e` for error info and f.assessment.sh.* for final.bam).

If you need to use this script to run multiple samples, you can use this command:

```bash
cat ../sample.list |while read i;do echo "nohup sh 01_qc_map.sh rawdata_path out_path $i yes|no ref &" >> run_01_qc_map.sh; done
sh run_01_qc_map.sh
```

## 02_map_dm6_spikerIN.sh

Mapping about ChIP-Seq spike-in normalization. the following parameters:

```bash
sh 02_map_dm6_spikerIN.sh <out_path> <sample> <yes|no>
```

- `out_path`: Current working directory.
- `sample`: The name of the ChIP-Seq sample.
- `yes|no`: Whether the data is paired-end (`yes`) or single-end (`no`).

The script performs the following steps:

1. Read Mapping: clean reads are aligned to the reference genome using [`bowtie2`](https://bowtie-bio.sourceforge.net/bowtie2/index.shtml).
2. Mark duplicates: The script uses [`picard`](https://broadinstitute.github.io/picard/) to mark duplicate reads in the aligned BAM file. The output is stored in a file named `<sample>.rmdup.bam`.
3. Filtering: Depending on whether the data is paired-end (`-q 10 -F1804`) or single-end (`-q 10 -F1024`), the script uses [`samtools`](http://www.htslib.org/) to filter the aligned reads based on mapping quality and flags. The filtered reads are stored in a file named `<sample>.final.bam`.
4. Additional analysis: Statistical mapping information (`assessment.sh.o` and `assessment.sh.e`).

## 02_scale.bw.sh

Used to normalize sequencing depth data, include RPM (reads per million) and spike-in normalization. the following parameters:

```bash
sh 02_scale.bw.sh <sample> <min_spike> <projectdir> <fai>
```

- `sample`: The name of the ChIP-Seq sample.
- `min_spike`: The lowest total records in 02_map_dm6/<sample>/f.assessment.sh.o file about IP sample.
- `projectdir`: Current working directory.
- `fai`: The reference genome file index, such as hg38.fa.fai.

The script performs the following steps:
1. Calculating scaling factors: `RPM = 10e6/mapped reads`, `spike-in = RPM*(min mapped reads/mapped reads)`
2. Generating RPM (Reads Per Million) file: The [`bedtools`](https://bedtools.readthedocs.io/en/latest/) tool is used to scale the `<sample>.bed` file based on the scaling factor RPM, and the output is saved as `<sample>.rpm.bedgraph` file. The file is then sorted to generate the `<sample>.sorted.rpm.bedgraph` file. Finally, the [bedGraphToBigWig](https://www.encodeproject.org/software/bedgraphtobigwig/) command is used to convert `<sample>.sorted.rpm.bedgraph` to `<sample>.rpm.bw` file.
3. Generating RPM and spike-in file: The [`bedtools`](https://bedtools.readthedocs.io/en/latest/) tool is used to scale the `<sample>.bed` file based on the scaling factor RPM, and the output is saved as `<sample>.min.bedgraph` file. The file is then sorted to generate the `<sample>.sorted.min.bedgraph` file. Finally, the [bedGraphToBigWig](https://www.encodeproject.org/software/bedgraphtobigwig/) command is used to convert `<sample>.sorted.min.bedgraph` to `<sample>.min.bw` file.


## 03_callpeak.sh

Call peaks by MACS2, filter peaks with blacklist and p-value < 1e9, fold_enrichment > 5. the following parameters:

```bash
sh 03_callpeak.sh <project_path> <tre> <con> <paire> <ref> <blacklist.bed>
```

- `project_path`: Current working directory.
- `tre`: The treatment sample name.
- `con`: The control sample name.
- `paire`: Whether the data is paired-end (`yes`) or single-end (`no`).
- `ref`: The reference genome file index, such as hg38.fa.fai.
- `blacklist.bed`: filter peaks with blacklist, such as mm10-blacklist.v2.bed and hg38-blacklist.v2.bed.

The script performs the following steps:

1. Peak calling: The script uses [`macs2`](https://hbctraining.github.io/Intro-to-ChIPseq/lessons/05_peak_calling_macs.html) to call peaks based on the treatment and control samples. It generates narrowPeak files (`<tre>-VS-<con>_peaks.narrowPeak`) and broadPeak files (`<tre>-VS-<con>_broad/<tre>-VS-<con>_peaks.broadPeak`).
2. Filtering: The script uses [`bedtools`](https://bedtools.readthedocs.io/en/latest/) to filter the called peaks by excluding regions specified in the blacklist file. The filtered peaks are stored in files with the suffix `.FB`.
3. Filterring: The script uses the `awk` command to filter the rows in the `<tre>-VS-<con>_peaks.broadPeak.FB` file that satisfy the given conditions and outputs the results to the `<tre>-VS-<con>_peaks.broadPeak.FB.hash.peak` file. The condition is that fold_enrichment is greater than 5 and the -lg(p-value) is greater than 9.

If you need to use this script to run multiple samples, you can use this command:

```bash
cat ../callpeak.sample.info |while read a b c;do echo "nohup sh 03_callpeak.sh project_path $a $b $c ref blacklist &" >> run_03call_peak.sh; done
sh run_03call_peak.sh
```

## 04_chromHMM.sh

Learning and characterizing chromatin states by [`ChromHMM`](https://compbio.mit.edu/ChromHMM/). the following parameters:

```bash
sh 04_chromHMM.sh <project_path> <ref>
```

- `project_path`: Current working directory.
- `ref`: The reference genome file.

The script performs the following steps:

1. Binarize BAM files: bam file changes to binary files by [`ChromHMM`](https://compbio.mit.edu/ChromHMM/) BinarizeBam.
2. Learn model: The script uses [`ChromHMM`](https://compbio.mit.edu/ChromHMM/) to learn a model based on the binarized data.
3. Reorder states: The script reorders the chromatin states based on a predefined order specified in the `chromhmm.reorder.hmnames.txt` file.
4. Make segmentation: The script performs analysis on other data using the trained model to generate segmentation files.
5. Overlap enrichment: The script uses [`ChromHMM`](https://compbio.mit.edu/ChromHMM/) to calculate overlap enrichment between the chromatin states and specified regions.
6. Heatmap plotting: This step is currently commented out in the script. It requires additional files (`emissions_15.txt` and `asyn_ol.txt`) to plot the heatmap.

Eg: use [GEO: GSE189563](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE189563) to learn model

![emissions_15](https://github.com/rickbingpan/ChIP-seq/assets/92712179/981f6c9f-09c1-44f1-977e-370958017461)


## 05_merge_overlap1_peak.sh

Merge and filter called peaks. the following parameters:

```bash
sh 05_merge_overlap1_peak.sh <project_path>
```

The script performs the following steps:

1. Peak merging: The script merges narrow peaks for each sample according to the `callpeak.sample.info` file. It generates merged peak files (`<sample>_overlap1.peaks`).
2. Peak filtering: The script can optionally filter the merged peaks by excluding regions specified in a blacklist file.

## 06_peakCenter_heatmap.sh

Plot distributed heatmap of peak centers. the following parameters:

```bash
sh 06_peakCenter_heatmap.sh <project_path> <peak> <sample>
```

- `project_path`: Current working directory.
- `peak`: peak file.
- `sample`: The name of the ChIP-seq sample.

The script performs the following steps:

1. Heatmap plotting: The script uses `computeMatrix` and `plotHeatmap` to generate a heatmap of the peak centers based on the raw/RPM/spike-in scaled bw file.

Eg: use [GEO: GSE189563](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE189563) to plot heatmap

![Uploading rep1.hm.rpm.png…]()


# Q&A
1. What are the ChIP-Seq data quality control criteria？
   
| feature | cutoff |
| --- | --- |
| total mapping reads | >80% |
| duplicates reads | <30% |
| Rip (Percentage of reads wthin peaks) | narrow peaks 5~30% |
| RelCC (Signal/Noise) | >1(IP), <1(Input) |
| IGV | show clear peaks |


2. What about noisy signals in learning and characterizing chromatin states?
   
We can sort the distribution of signal values and use `ChromHMM.jar BinarizeSignal -g` to filter out peaks of low signals.

# Conclusion

This ChIP-Seq pipeline provides a set of scripts for processing ChIP-Seq data and performing downstream analysis. Each script performs specific tasks, such as quality control, mapping, peak calling, ChIPqc, and learning and characterizing chromatin states. By following this pipeline, researchers can efficiently analyze their ChIP-seq data and gain a deeper understanding of the underlying biological processes.
