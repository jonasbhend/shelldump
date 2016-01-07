#!/bin/bash

## this script is used to compute DTR from daily maximum and minimum temperature

dpath=/store/msclim/bhendj/EUPORIAS


## ERA-INT
for obs in ERA-INT E-OBS ; do
    cd $dpath/$obs
    for grid in * ; do
        cd $dpath/$obs/$grid/daily
        if [[ -d tasmax && -d tasmin ]] ; then
            echo $obs $grid
            tasmaxfile=$( \ls tasmax/*.nc | head -1 )
            tasminfile=$( \ls tasmin/*.nc | head -1 )

            if [[ ! -d dtr ]] ; then
                mkdir dtr
            fi
            outfile=$( echo $tasmaxfile | sed -e "s/tasmax/dtr/g" -e "s/tx/dtr/g" ) 
            cdo -s -L abs -sub $tasmaxfile $tasminfile $outfile
            varname=$( cdo -s showvar $outfile | sed 's/ //g')
            ncrename -h -v $varname,dtr $outfile
            ncatted -h -a long_name,dtr,o,c,'diurnal temperature range' $outfile
        fi
    done
done

## system4 forecasts

cd $dpath/ecmwf-system4
for grid in * ; do
    cd $dpath/ecmwf-system4/$grid/daily
    if [[ -d tasmax && -d tasmin ]] ; then
        if [[ ! -f dtr/none ]] ; then
            mkdir -p dtr/none
        fi
        echo ecmwf-system4 $grid
        tasmaxfiles=$( \ls tasmax/none/????0501_*.nc tasmax/none/????1101_*.nc )
        for tasmaxfile in $tasmaxfiles ; do
            tasminfile=$( echo $tasmaxfile | sed -e 's/tasmax/tasmin/g' -e 's/_51_/_52_/g' )
            if [[ -f $tasminfile ]] ; then
                outfile=$( echo $tasmaxfile | sed -e 's/tasmax/dtr/g' -e 's/_51_/_dtr_/g' )
                cdo -s sub $tasmaxfile $tasminfile $outfile
                varname=$(cdo -s showvar $outfile | sed 's/ //g' )
                ncrename -h -v $varname,dtr $outfile
                ncatted -h -a long_name,dtr,o,c,'diurnal temperature range' $outfile
            fi
        done
    fi
done



exit