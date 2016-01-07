# sbatch_run_plot_skill_scores.sh --- 
# 
# Filename: sbatch_run_plot_skill_scores.sh
# Description: 
# Author: Jonas Bhend
# Maintainer: 
# Created: Thu Oct 16 16:48:24 2014 (+0200)
# Version: 
# Last-Updated: Tue Nov 11 16:44:26 2014 (+0100)
#           By: Jonas Bhend
#     Update #: 4
# URL: 
# Keywords: 
# Compatibility: 
# 
# 

# Commentary: 
# 
# 
# 
# 

# Code:



dpath=/store/msclim/bhendj/EUPORIAS/skill_scores/eobs0.44/seasonal

## set the current path
workdir=`pwd`

cd $dpath

## loop through variable name and debiasing options
for index in * ; do 
    
    cd $dpath/$index

    for infile in * ; do
        
        ## set random component for batch job file
        batchfile=$HOME/logs/sbatch_plot_skill_$RANDOM.sh
                
        ## write the batch file
        cat > $batchfile <<EOF
#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=plot_skill
#SBATCH --mail-type=FAIL
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1GB
#SBATCH --partition=postproc
#SBATCH --output=plot_skill_%j.log

#======START=====
srun Rscript /users/bhendj/R/plot_skill.R $dpath/$index/$infile

EOF

        ## actually run the batch job
        cd $workdir
        sbatch $batchfile
        rm $batchfile

    done ## end of loop on files
done ## end of loop on indices

exit

# 
# sbatch_run_plot_skill_scores.sh ends here
