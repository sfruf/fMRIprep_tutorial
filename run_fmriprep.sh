#!/bin/bash

export STUDY=/path/to/some/folder
sbatch --array=1-$(( $( wc -l $STUDY/data/participants.tsv | cut -f1 -d' ' ) - 1 )) sbatch_fmriprep.slurm
