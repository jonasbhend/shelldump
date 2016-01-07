#!/bin/bash

## script to remap the WFDEI to the EAF-22 grid (eastern Africa)
## or any other grid specified in the grids directory

datapath=/store/msclim/Prediction/WFDEI
grid=EAF-22
gridfile=/store/msclim/bhendj/EUPORIAS/grids/$grid.grid
WFDEIgrid=/store/msclim/bhendj/EUPORIAS/grids/WFDEI.grid
echo "Remap WFDEI for $grid"

TMPDIR=$SCRATCH/regridWFDEI_$RANDOM
mkdir -p $TMPDIR

for varname in tas tasmax tasmin pr ; do
    wname=$varname
    if [[ "$varname" == "tas" ]] ; then
        wname=Tair
    elif [[ "$varname" == "pr" ]] ; then
        wname=Rainf
    fi
    vardir=$(\ls -d $datapath/${wname}_daily_WFDE*)
    
    ## unzip all daily data
    cd $vardir
    gunzip *.gz
    
    ## loop through files to remap
    for f in *.nc ; do
        cdo -s setgrid,$WFDEIgrid -selvar,$wname $f $TMPDIR/tmp.$f
        if [[ ! -f $TMPDIR/gridweights.tmp ]] ; then
            cdo -s gencon,$gridfile $TMPDIR/tmp.$f $TMPDIR/gridweights.tmp
        fi
        cdo -s remap,$gridfile,$TMPDIR/gridweights.tmp $TMPDIR/tmp.$f $TMPDIR/${f/.nc/_$grid.nc}
        rm $TMPDIR/tmp.$f
    done

    ## merge the data 
    outfile=WFDEI_${varname}_1979-2014_${grid}.nc
    cdo -r -s mergetime $TMPDIR/*.nc $TMPDIR/tmp.$outfile
    cdo -s -r settaxis,1979-01-01,12:00,1days $TMPDIR/tmp.$outfile $TMPDIR/$outfile
    rm $TMPDIR/tmp.$outfile
    if [[ $varname == "tas" || $varname == "pr" ]] ; then
        ncrename -h -v $wname,$varname $TMPDIR/$outfile
    fi

    ## copy to directory structure
    outdir=/store/msclim/bhendj/EUPORIAS/WFDEI/$grid/daily/$varname
    if [[ ! -d $outdir ]] ; then
        mkdir -p $outdir
    fi
    mv $TMPDIR/$outfile $outdir


    ## remove all the netcdf files from $TMPDIR
    rm $TMPDIR/*.nc

    ## rezip all the NetCDF files (works well due to missing values)
    ## cd $vardir
    ## gzip *.nc
done


rm -rf $TMPDIR
exit