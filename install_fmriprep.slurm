#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=4:00:00
#SBATCH --job-name=fmriprep_install
#SBATCH --partition=short
#SBATCH --mem=50Gb
#SBATCH --cpus-per-task=1

module load singularity/3.4.1
singularity build /home/sebruf/fmriprep.simg docker://poldracklab/fmriprep


