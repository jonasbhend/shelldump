#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=convert2eobs
#SBATCH --mail-type=FAIL
#SBATCH --time=05:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=12GB
#SBATCH --partition=postproc
#SBATCH --output=convert2eobs_%j.log


#======START=====

## dpath=/store/msclim/Prediction/Seasonal/ecmwf-system4/daily/global/Data_from_APN
dpath=/store/msclim/sysclim/ecmwf/system4/daily/deg075
gridpath=/store/msclim/bhendj/EUPORIAS/grids
grid=eobs0.44
#mask=mask_0.44deg_rot_v10.0.nc
ftrunc="_eobs.nc"
opath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/$grid/daily

cd $dpath
for varname in Tavg ; do 

    TMPDIR=$SCRATCH/regrid_${varname}_${RANDOM}
    mkdir $TMPDIR

    echo $varname
   
    ## check whether directory exists else create
    if [[ ! -f $opath/$varname ]] ; then
	mkdir -p $opath/$varname
    fi
    
    cd $dpath/$varname
    for f in 201[4-5]????_*${ftrunc} ; do
	
        echo $f

	outfile=$opath/$varname/${f/eobs/${grid}}
	ensfile=$opath/$varname/ensmean_${f/eobs/${grid}}
	
        ## convert seasonal file to new grid
	## cdo -s ifthen $gridpath/$mask -remapcon,$gridpath/$grid.grid -setgrid,$gridpath/ecmwf-system4.grid $f $TMPDIR/$f
        cdo -s remapcon,$gridpath/$grid.grid $f $TMPDIR/$f

        ## disaggregate the rainfall time series
        if [[ $varname == "Precip" ]] ; then

            ## check that accumulated precip is strictly increasing
            cdo -s -L mergetime -seltimestep,1 $TMPDIR/$f -runmax,2 $TMPDIR/$f $TMPDIR/$f.tmp
            
            ## compute disaggregated rainfall series using runstd
            cdo -s -L mergetime -seltimestep,1 $TMPDIR/$f.tmp -mulc,2 -runstd,2 $TMPDIR/$f.tmp $TMPDIR/$f

            ## rename variables and attributes
            ncrename -h -v tp,pr $TMPDIR/$f
            ncatted -h -a long_name,pr,o,c,"total precipitation" $TMPDIR/$f
          
            ncrename -h -O -v time,time2 $TMPDIR/$f $TMPDIR/$f.tmp
            ncks -A -v time $f $TMPDIR/$f.tmp
            ncks -O -x -v time2 $TMPDIR/$f.tmp $TMPDIR/$f

            rm $TMPDIR/$f.tmp
        fi

	## copy with netcdf compression
	nccopy -d9 $TMPDIR/$f $outfile

	## compute ensemble mean with ncwa
	## ncwa -O -a epsd_1 $outfile $ensfile

	## remove file from scratch
	rm $TMPDIR/$f

    done

    rm -rf $TMPDIR

done


      
#=====END=====
