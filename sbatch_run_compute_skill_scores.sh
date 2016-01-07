# sbatch_run_compute_skill_scores.sh --- 
# 
# Filename: sbatch_run_compute_skill_scores.sh
# Description: 
# Author: Jonas Bhend
# Maintainer: 
# Created: Tue Oct 14 10:39:26 2014 (+0200)
# Version: 
# Last-Updated: Thu Nov 27 15:53:10 2014 (+0100)
#           By: Jonas Bhend
#     Update #: 86
# URL: 
# Keywords: 
# Compatibility: 
# 
# 

# Commentary: 
#  Script to compute seasonal (3-monthly) skill metrics from CIIs
#  computed on daily time series.
# 
# 

# Change Log:
# 
# 
# 

# Code:

grid=eobs0.44
dpath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/$grid/monthly
outpath=/store/msclim/bhendj/EUPORIAS/skill_scores/$grid/seasonal
 
## set the current path
workdir=`pwd`


## loop through variable name and debiasing options
for index in FD HDD HDDch CDD tas tasmin ; do 
    
    ## go to the respective directory to find methods
    cd $dpath/$index

    for method in * ; do
        
        
        ## get the observation file
        if [[ $method =~ "E-OBS" ]] ; then
            oname="E-OBS"
        elif [[ $method =~ "ERA-INT" ]] ; then
            oname="ERA-INT"
        elif [[ $grid =~ "eobs" && $method == "none" ]] ; then
            oname="E-OBS"
        fi

        opath=/store/msclim/bhendj/EUPORIAS/$oname/$grid/monthly/$index
        obsfile=`\ls $opath/*.nc`
        ofile=`basename $obsfile`            

        cd $dpath/$index/$method
        ## get the file names
        files=`\ls *.nc`
        
        ## get initmonths
        initmonths=''
        for f in $files ; do 
            imon=`echo $f | sed -e "s/${index}_....//g" -e "s/.._.*//g"`
            if [[ $initmonths != *${imon}* ]] ; then
                initmonths="$initmonths $imon"
            fi
        done
        
        ## loop through initmonths
        for initmon in $initmonths ; do

            cd $dpath/$index/$method
            files=`\ls ${index}_????${initmon}??_*.nc`

            ## convert to whitespace delimited             
            fcfiles=''
            for f in $files ; do
                fcfiles="$fcfiles $dpath/$index/$method/$f"
            done
            
            if [[ $files != "" ]] ; then
                
                ## set random component for batch job file
                batchfile=$HOME/logs/sbatch_compute_skill_${index}_${method}_initmon${initmon}.sh
                
                ## write the batch file
                cat > $batchfile <<EOF
#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=compute_skill
#SBATCH --mail-type=FAIL
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=12GB
#SBATCH --partition=postproc
#SBATCH --output=compute_skill_${index}_${method}_initmon${initmon}_%j.log

#======START=====
srun Rscript /users/bhendj/R/compute_skill.R $index $method $initmon $fcfiles $obsfile $outpath/$index

EOF

                ## actually run the batch job
                cd $workdir
                sbatch $batchfile
                rm $batchfile

            fi ## end of check on empty file namesn
        done ## end of loop on init months
    done ## end of loop on methods
done ## end of loop on indices

exit

# 
# sbatch_run_compute_skill_scores.sh ends here
