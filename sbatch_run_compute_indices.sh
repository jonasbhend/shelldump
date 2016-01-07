#!/usr/local/bin/bash
# sbatch_run_compute_indices.sh --- 
# 
# Filename: sbatch_run_compute_indices.sh
# Description: 
# Author: Jonas Bhend
# Maintainer: 
# Created: Tue Sep 23 16:43:34 2014 (+0200)
# Version: 
# Last-Updated: Thu Nov 27 15:37:37 2014 (+0100)
#           By: Jonas Bhend
#     Update #: 87
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

## path structure
## /store/msclim/bhendj/EUPORIAS/%data%/%grid%/%timres%/%varname%[/%method%]

dpath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/eobs0.44
opath=/store/msclim/bhendj/EUPORIAS/E-OBS
opath2=/store/msclim/bhendj/EUPORIAS/ERA-INT

grid=eobs0.44

## set the current path
workdir=`pwd`



initmonths="11 05"
for initmon in 11 ; do 
    
    if [[ $initmon == "05" ]] ; then
        indices="tas CDD"
    else
        indices="tas HDD HDDch FD"
    fi

    ## loop through variable name and debiasing options
    for index in $indices ; do 
        case $index in
            HDD)
                varname=tas
                ovar=tg
                ;;
            FD)
                varname=tasmin
                ovar=tn
                ;;
            CDD) 
                varname=tas
                ovar=tg
                ;;
            HDDch)
                varname=tas
                ovar=tg
                ;;
            tas)
                varname=tas
                ovar=tg
                ;;
            tasmin)
                varname=tasmin
                ovar=tn
                ;;
            tasmax) 
                varname=tasmax
                ovar=tx
                ;;
        esac
        
    ## get the observation file
        obsfile=`\ls $opath/$grid/daily/$varname/${ovar}_0.44deg_rot_v10.0.nc`
        ofile=`basename $obsfile`
        obsfile2=`\ls $opath2/$grid/daily/$varname/erainterim_${varname}_*.nc`
        ofile2=`basename $obsfile2`

    ## go to the respective directory to find methods
        cd $dpath/daily/$varname

        for method in * ; do
            
            ## set random component for batch job file
            batchfile=$HOME/logs/sbatch_compute_index_${index}_${method}_$RANDOM.sh
            
            cd $dpath/daily/$varname/$method
            ## get the file names
            files=`\ls ????${initmon}??_*.nc`
            fcfiles=''
            for f in $files ; do
                fcfiles="$fcfiles $f"
            done
            
            if [[ $files != "" ]] ; then
                
            ## write the batch file
                cat > $batchfile <<EOF
#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=compute_index
#SBATCH --mail-type=FAIL
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=18GB
#SBATCH --partition=postproc
#SBATCH --output=compute_index_${index}_${method}_%j.log

#======START=====
## compute indices for forecast files
for f in $fcfiles ; do
    if [[ ! -f $dpath/monthly/$index/$method/${index}_\$f  ]] ; then
        $HOME/code/compute_indices_from_daily_series.sh $dpath/daily/$varname/$method/\$f $dpath/monthly/$index/$method/${index}_\$f $index $varname true
    fi
done

## compute index for observation file
if [[ ! -f $opath/$grid/monthly/$index/${index}_$ofile ]] ; then
    $HOME/code/compute_indices_from_daily_series.sh $obsfile $opath/$grid/monthly/$index/${index}_$ofile $index $varname false
fi

## compute index for observation file
if [[ ! -f $opath2/$grid/monthly/$index/${index}_$ofile2 ]] ; then
    $HOME/code/compute_indices_from_daily_series.sh $obsfile2 $opath2/$grid/monthly/$index/${index}_$ofile2 $index $varname false
fi


EOF

                ## make output directory
                ## mkdir -p $dpath/monthly/$index/$method
                ## mkdir -p $opath/monthly/$index

                ## actually run the batch job
                cd $workdir
                sbatch $batchfile
                rm $batchfile

            fi ## end of check on empty file names

        done ## end of loop on methods
    done ## end of loop on indices
done ## end of loop on initmonths

exit
# 
# sbatch_run_compute_indices.sh ends here
