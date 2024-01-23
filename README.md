# Introduction
ChIP-seq pipeline is a bioinformatics analysis pipeline used for Chromatin ImmunopreciPitation sequencing (ChIP-seq) data.

on release, the rawdata for the pipeline testing is histone and transcription factor IP experiments from ([GEO: GSE189563](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE189563).

The pipeline is designed to process QC, mapping, calling peak, ChIPQC, chromHMM for ChIP-seq data. 
overview of ChIP-seq pipeline:
![peak pipeline](https://github.com/rickbingpan/ChIP-seq/assets/92712179/47ae80d5-bfa5-4953-895f-d3f541a67050)

## Prerequisites

Before running the pipeline, make sure you have the following requirements:

- Raw ChIP-seq data files in FASTQ format
- Reference genome files for the target species(mm10 and dm6)
- Installed software packages: `fastp`, `bowtie2`, `samtools`, `picard`, `bam_stat.py`, `macs2`, `deeptools`, `ChromHMM`, and `bedtools`

Please refer to the documentation of each software package for installation instructions.

You also have to prepare some files:

1. call.peak.info: It contains 3 columns, treatment(IP sample) , control(INPUT sample), heat_name.
2. sample.list: It contains 1 column, sample.
3. chromHMM.HM.txt: It contains 4 columns, such as `asyn	H3K27ac	asyn_H3K27ac_rep1.final.bam	asyn_input_rep1.final.bam`
4. chromhmm.reorder.hmnames.txt: It contains a Histone name every row, such as</br>
      H3K4me3</br>
      H3K27ac</br>
      ...
5. chromhmm.reorder.states.txt: It contains 2 colomuns, raw state      reorder state(start from 1)


## 01_qc_map.sh

This script performs quality control (QC) and mapping of the ChIP-seq raw data. It takes the following parameters:

```bash
sh 01_qc_map.sh <rawdata_path> <out_path> <sample> <yes|no> <ref>
```

- `rawdata_path`: The path to the directory containing the raw data files.
- `out_path`: The output directory where the results will be stored.
- `sample`: The name of the ChIP-seq sample.
- `yes|no`: Whether the data is paired-end (`yes`) or single-end (`no`).
- `ref`: The reference genome file index, such as hg38.fa.fai.

The script performs the following steps:

1. Quality Control: FastQC and Trim Galore! are used to assess and trim raw sequencing data, ensuring high-quality reads for mapping.
2. Read Mapping: Processed reads are aligned to the reference genome using Bowtie2.
3. Marking Duplicates: Picard Tools are used to mark potential PCR duplicates in the aligned reads.
4. Result Conversion to BigWig: The final aligned, sorted, and processed BAM files are converted into BED format, and then into bedgraph format, followed by conversion to BigWig format using bedGraphToBigWig for visualization purposes.
5. Additional analysis: The script generates assessment statistics (`assessment.sh.o` for rmdup.bam map results , `assessment.sh.e` for error info and f.assessment.sh.* for final.bam).

If you need to use this script to run multi samples, you can use this command:

```bash
cat ../sample.list |while read i;do echo "nohup sh 01_qc_map.sh rawdata_path out_path $i yes|no ref &" >> run_01_qc_map.sh; done
sh run_01_qc_map.sh
```

## 02_map_dm6_spikerIN.sh

This script performs mapping of ChIP-seq data to the Drosophila melanogaster (dm6) genome. It takes the following parameters:

```bash
sh 02_map_dm6_spikerIN.sh <out_path> <sample> <yes|no>
```

- `out_path`: The output directory where the results will be stored.
- `sample`: The name of the ChIP-seq sample.
- `yes|no`: Whether the data is paired-end (`yes`) or single-end (`no`).

The script performs the following steps:

1. Mapping: The script uses `bowtie2` to align the clean reads to the dm6 reference genome. If the data is paired-end, it aligns both read files from the previous step. If the data is single-end, it aligns a single read file. The output is stored in BAM format (`<sample>.bam`).
2. Mark duplicates: The script uses `picard` to mark duplicate reads in the aligned BAM file. The output is stored in a file named `<sample>.rmdup.bam`.
3. Filtering: Depending on whether the data is paired-end or single-end, the script uses `samtools` to filter the aligned reads based on mapping quality and flags. The filtered reads are stored in a file named `<sample>.final.bam`.
4. Additional analysis: The script generates assessment statistics (`assessment.sh.o` and `assessment.sh.e`).

## 02_scale.bw.sh

This script is designed for processing bed data by normalizing coverage data to RPM (reads per million) and considering spike-in controls. It takes the following parameters:

```bash
sh 02_scale.bw.sh <sample> <min_spike> <projectdir> <fai>
```

- `sample`: The name of the ChIP-seq sample.
- `min_spike`: The lowest value in 01_qc_map/<sample>/f.assessment.sh.o file's Total records, it need IP sample.
- `projectdir`: The path to the project directory.
- `fai`: The reference genome file index, such as hg38.fa.fai.

The script performs the following steps:
1. Calculating scaling factors: By parsing the information in the `01_qc_map/<sample>//f.assessment.sh.o` file, the values of `rpm` and `rpm_spike` are obtained. Two scaling factors, `sf1` and `sf2`, are calculated based on these values. Finally, the final scaling factor, `sf`, is calculated using these two factors.
2. Generating RPM (Reads Per Million) file: The `bedtools genomecov` command is used to scale the `<sample>.bed` file based on the scaling factor `sf1`, and the output is saved as `<sample>.rpm.bedgraph` file. The file is then sorted to generate the `<sample>.sorted.rpm.bedgraph` file. Finally, the `bedGraphToBigWig` command is used to convert `<sample>.sorted.rpm.bedgraph` to `<sample>.rpm.bw` file.
3. Generating RPM and spikeIN file: The `bedtools genomecov` command is used to scale the `<sample>.bed` file based on the scaling factor `sf`, and the output is saved as `<sample>.min.bedgraph` file. The file is then sorted to generate the `<sample>.sorted.min.bedgraph` file. Finally, the `bedGraphToBigWig` command is used to convert `<sample>.sorted.min.bedgraph` to `<sample>.min.bw` file.


## 03_callpeak.sh

This script performs peak calling using MACS2, filter peaks use black list and p-value < 1e9, fold_enrichment > 5. It takes the following parameters:

```bash
sh 03_callpeak.sh <project_path> <tre> <con> <paire> <ref> <blacklist.bed>
```

- `project_path`: The path to the project directory.
- `tre`: The treatment sample name.
- `con`: The control sample name.
- `paire`: The sequencing technology used in the sample, if it is Pair-end, enter "yes".
- `ref`: The reference genome file index, such as hg38.fa.fai.
- `blacklist.bed`: A file containing regions to be excluded from peak calling, such as mm10-blacklist.v2.bed and hg38-blacklist.v2.bed.

The script performs the following steps:

1. Peak calling: The script uses MACS2 to call peaks based on the treatment and control samples. It generates narrowPeak files (`<tre>-VS-<con>_peaks.narrowPeak`) and broadPeak files (`<tre>-VS-<con>_broad/<tre>-VS-<con>_peaks.broadPeak`).
2. Filtering: The script uses `bedtools` to filter the called peaks by excluding regions specified in the blacklist file. The filtered peaks are stored in files with the suffix `.FB`.
3. Filterring: The script uses the awk command to filter the rows in the `<tre>-VS-<con>_peaks.broadPeak.FB` file that satisfy the given conditions and outputs the results to the `<tre>-VS-<con>_peaks.broadPeak.FB.hash.peak` file. The condition is that fold_enrichment is greater than 5 and the -lg(p-value) is greater than 9.

If you need to use this script to run multi samples, you can use this command:

```bash
cat ../callpeak.sample.info |while read a b c;do echo "nohup sh 03_callpeak.sh project_path $a $b $c ref blacklist &" >> run_03call_peak.sh; done
sh run_03call_peak.sh
```

## 04_chromHMM.sh

This script performs chromatin state analysis using ChromHMM. It takes the following parameters:

```bash
sh 04_chromHMM.sh <project_path> <ref>
```

- `project_path`: The path to the project directory.
- `ref`: The reference genome file.

The script performs the following steps:

1. Binarize BAM files: The script uses `ChromHMM` to binarize the BAM files generated in the previous steps.
2. Learn model: The script uses `ChromHMM` to learn a model based on the binarized data.
3. Reorder states: The script reorders the chromatin states based on a predefined order specified in the `chromhmm.reorder.hmnames.txt` file.
4. Analysis: The script performs analysis on other data using the trained model and generates segmentation files.
5. Overlap enrichment: The script uses `ChromHMM` to calculate overlap enrichment between the chromatin states and specified regions.
6. Heatmap plotting: This step is currently commented out in the script. It requires additional files (`emissions_15.txt` and `asyn_ol.txt`) to plot the heatmap.


## 05_merge_overlap1_peak.sh

This script merges and filters called peaks to generate a consolidated set of peaks. It takes no parameters.

```bash
sh 05_merge_overlap1_peak.sh
```

The script performs the following steps:

1. Peak merging: The script merges called peaks for each sample specified in the `callpeak.sample.info` file. It generates merged peak files (`<sample>_overlap1.peaks`).
2. Peak filtering: The script can optionally filter the merged peaks by excluding regions specified in a blacklist file.

## 06_peakCenter_heatmap.sh

This script generates a heatmap of peak centers. It takes the following parameters:

```bash
sh 06_peakCenter_heatmap.sh <project_path> <sample> <ref.fai>
```

- `project_path`: The path to the project directory.
- `sample`: The name of the ChIP-seq sample.
- `ref.fai`: The index file for the reference genome, such as mm10.fa.fai.

The script performs the following steps:

1. RPM calculation: The script calculates the reads per million (RPM) value for the ChIP-seq sample based on the assessment statistics. It generates a bedGraph file with the RPM values.
2. Conversion to BigWig: The script converts the bedGraph file to BigWig format.
3. Heatmap plotting: The script uses `computeMatrix` and `plotHeatmap` to generate a heatmap of the peak centers based on the RPM values.

## Conclusion

This ChIP-seq pipeline provides a comprehensive set of scripts for processing ChIP-seq data and performing downstream analysis. Each script performs specific tasks, such as quality control, mapping, peak calling, and chromatin state analysis, to generate valuable insights into the genomic regions of interest. By following this pipeline, researchers can efficiently analyze their ChIP-seq data and gain a deeper understanding of the underlying biological processes.
