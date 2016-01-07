#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=eraint2eobs
#SBATCH --mail-type=FAIL
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=12GB
#SBATCH --partition=postproc
#SBATCH --output=eraint2eobs_%j.log


#======START=====

## dpath=/store/msclim/Prediction/Seasonal/ecmwf-system4/daily/global/Data_from_APN
## dpath=/store/msclim/sysclim/ecmwf/system4/daily/deg075
dpath=/store/msclim/Prediction/ERAINTERIM
gridpath=/store/msclim/bhendj/EUPORIAS/grids
grid=eobs0.44
mask=mask_0.44deg_rot_v10.0.nc
ftrunc="_eobs.nc"
opath=/store/msclim/bhendj/EUPORIAS/ERA-INT/daily/$grid

for varname in tas ; do 
   
    ## check whether directory exists else create
    if [[ ! -f $opath/$varname ]] ; then
	mkdir -p $opath/$varname
    fi
    
    TMPDIR=$SCRATCH/erainterim_$RANDOM
    mkdir -p $TMPDIR
    
    cd $dpath/$varname/daily
    cdo -s -r mergetime erainterim_${varname}_????.nc $TMPDIR/erainterim.nc

    cdo -s remapcon,$gridpath/$grid.grid $TMPDIR/erainterim.nc $TMPDIR/erainterim_${varname}_$grid.nc

    nccopy -d9 $TMPDIR/erainterim_${varname}_$grid.nc $opath/$varname/erainterim_${varname}_1981-2012_$grid.nc
 
    rm -rf $TMPDIR

done
 
exit


      
#=====END=====
