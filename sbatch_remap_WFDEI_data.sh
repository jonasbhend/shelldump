#!/bin/bash -l

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=regridWFDEI
#SBATCH --mail-type=FAIL
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=18GB
#SBATCH --partition=postproc
#SBATCH --output=regridWFDEI_%j.log

srun /users/bhendj/code/remap_WFDEI_data.sh
