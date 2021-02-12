#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=48:00:00
#SBATCH --job-name=fmriprep_run
#SBATCH --partition=long
#SBATCH --mem-per-cpu=16Gb
#SBATCH --cpus-per-task=4

#SBATCH -o /scratch/sebruf/%x-%A-%a.out
#SBATCH -e /scratch/sebruf/%x-%A-%a.err
#SBATCH --mail-user=s.ruf@northeastern.edu
#SBATCH --mail-type=ALL

module load singularity/3.4.2

BIDS_DIR="$STUDY"
DERIVS_DIR="derivatives/fmriprep"
LOCAL_FREESURFER_DIR="$STUDY/derivatives/freesurfer-6.0.1"

# Prepare some writeable bind-mount points.
TEMPLATEFLOW_HOST_HOME=$HOME/.cache/templateflow
FMRIPREP_HOST_CACHE=$HOME/.cache/fmriprep
mkdir -p ${TEMPLATEFLOW_HOST_HOME}
mkdir -p ${FMRIPREP_HOST_CACHE}

# Prepare derivatives folder
mkdir -p ${BIDS_DIR}/${DERIVS_DIR}

# Make sure FS_LICENSE is defined in the container.
export SINGULARITYENV_FS_LICENSE=$HOME/.freesurfer.txt

# Designate a templateflow bind-mount point
export SINGULARITYENV_TEMPLATEFLOW_HOME="/templateflow"


SINGULARITY_CMD="singularity run --home $HOME --cleanenv -B $BIDS_DIR:/data -B ${TEMPLATEFLOW_HOST_HOME}:${SINGULARITYENV_TEMPLATEFLOW_HOME} -B /scratch/sebruf/fmriprep_files:/work -B ${LOCAL_FREESURFER_DIR}:/fsdir $HOME/fmriprep.simg"

# Parse the participants.tsv file and extract one subject ID from the line corresponding to this SLURM task.
subject=$( sed -n -E "$((${SLURM_ARRAY_TASK_ID} + 1))s/sub-(\S*)\>.*/\1/gp" ${BIDS_DIR}/participants.tsv )
#export subject=03
# Remove IsRunning files from FreeSurfer
find ${LOCAL_FREESURFER_DIR}/sub-$subject/ -name "*IsRunning*" -type f -delete

# Compose the command line
cmd="${SINGULARITY_CMD} /data /data/${DERIVS_DIR} participant --participant-label $subject -w /work/ -vv --omp-nthreads 8 --nthreads 12 --mem_mb 160000 --output-spaces MNI152NLin2009cAsym:res-2 anat fsnative fsaverage5 --skull-strip-t1w force --use-aroma --fs-subjects-dir /fsdir"

# Setup done, run the command
echo Running task ${SLURM_ARRAY_TASK_ID}
echo Commandline: $cmd
eval $cmd
exitcode=$?

# Output results to a table
echo "sub-$subject   ${SLURM_ARRAY_TASK_ID}    $exitcode" \
      >> ${SLURM_JOB_NAME}.${SLURM_ARRAY_JOB_ID}.tsv
echo Finished tasks ${SLURM_ARRAY_TASK_ID} with exit code $exitcode
exit $exitcode

