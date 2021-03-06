#!/bin/bash -l
#SBATCH --job-name=mosaic_slope
#SBATCH --account=Project_2003061
#SBATCH --output=output_%j.txt
#SBATCH --error=errors_%j.txt
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --partition=hugemem
#SBATCH --mem=800G

# Load r-env-singularity
module load r-env-singularity

# Clean up .Renviron file in home directory
if test -f ~/.Renviron; then
    sed -i '/TMPDIR/d' ~/.Renviron
    sed -i '/OMP_NUM_THREADS/d' ~/.Renviron
fi

# Specify a temp folder path
echo "TMPDIR=/scratch/project_2003061/temp" >> ~/.Renviron

# Run the R script
srun singularity_wrapper exec Rscript --no-save --slave mosaic_slope.R