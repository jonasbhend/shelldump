#!/bin/bash

dpath=/store/msclim/bhendj/EUPORIAS
ndays=31

observations="ERA-INT E-OBS"
## observations="GHCN"
## for obs in $observations ; do
for obs in ERA-INT ; do
    echo $obs
    if [[ $obs == "ERA-INT" ]] ; then
        grids="global2 eobs0.44"
    elif [[ $obs == "GHCN" ]] ; then
        grids="nomissval"
    else
        grids="eobs0.44"
    fi
    for grid in $grids ; do
    ## for grid in global2 ; do
        echo $grid
        varnames=$( echo $(\ls -d $dpath/$obs/$grid/daily/*) | sed "s_$dpath/$obs/$grid/daily/__g" )
        ## for varname in $varnames ; do
        for varname in tas ; do
            echo $varname
            if [[ ! -d $dpath/$obs/$grid/daily/$varname ]] ; then
                continue
            fi

            obsfile=$( \ls $dpath/$obs/$grid/daily/$varname/*.nc | head -1)
            if [[ ! -f $obsfile ]] ; then
                continue
            fi
            outdir=$dpath/$obs/$grid/fx/$varname
            if [[ ! -f $outdir ]] ; then
                mkdir -p $outdir
            fi
            
            ofile=${obs}_${varname}_1981-2010.nc
            cdo -s seldate,1981-01-01,2010-12-31 $obsfile $SCRATCH/$ofile
            cdo -s ydrunmin,$ndays $SCRATCH/$ofile $SCRATCH/timmin.$ofile
            cdo -s ydrunmax,$ndays $SCRATCH/$ofile $SCRATCH/timmax.$ofile

            ##for pctl in 01 02 05 10 20 30 40 50 60 70 80 90 95 98 99 ; do
            for pctl in 25 75 ; do
                echo $pctl
                cdo -s ydrunpctl,$pctl,$ndays $SCRATCH/$ofile $SCRATCH/timmin.$ofile $SCRATCH/timmax.$ofile $outdir/pctl${pctl}_$ofile 
                ## Rscript /users/bhendj/R/compute_seasonal_percentiles.R $SCRATCH/$ofile $pctl $outdir/seaspctl${pctl}_$ofile
            done
            rm $SCRATCH/$ofile $SCRATCH/*$ofile
            
        done
    done
done

