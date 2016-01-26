#!/bin/bash

## compute the evapotranspiration from (bias corrected) tasmin and tasmax

grid=EAF-22
methods="none fastqqmap_1991-2012_WFDEI fastqqmap_debias_1991-2012_WFDEI"

## observations
obs=WFDEI

obspath=/store/msclim/bhendj/EUPORIAS/$obs/$grid/daily
tminfile=$(ls $obspath/tasmin/*.nc )
tmaxfile=$(ls $obspath/tasmax/*.nc )
eptfile=$( echo $tminfile | sed 's/tasmin/ept/g' )

if [[ ! -f $eptfile ]] ; then
    mkdir -p $( dirname $eptfile )
    echo "compute evapotranspiration for $obs"
    compute_evapotranspiration.sh "$tminfile" "$tmaxfile" "$eptfile"
fi

## model runs
for method in $methods ; do
    for model in ecmwf-system4 SMHI-EC-EARTH SMHI-RCA4 UCAN-WRF341G UL-IDL-WRF360D DWD-CCLM4-8-21 ; do
    # for model in ecmwf-system4 ; do
        echo $model $method
        modpath=/store/msclim/bhendj/EUPORIAS/$model/$grid/daily
        tmaxfiles=$( \ls $modpath/tasmax/$method/*.nc )
        for tmax in $tmaxfiles ; do
            tmin=$( echo $tmax | sed 's/tasmax/tasmin/g' )
            if [[ -f $tmin ]] ; then
                ept=$( echo $tmax | sed 's/tasmax/ept/g' )
                if [[ ! -f $ept ]] ; then
                    compute_evapotranspiration.sh "$tmin" "$tmax" "$ept"
                fi
            fi
        done
    done
done



## compute the water balance from daily evapotranspiration and rainfall

prfile=$(ls $obspath/pr/*.nc )
eptfile=$(ls $obspath/ept/*.nc )
wbfile=$( echo $eptfile | sed 's/ept/wb/g' )


if [[ -f $prfile && -f $eptfile && ! -f $wbfile ]] ; then
    echo "compute water balance for $obs"
    mkdir -p $( dirname $wbfile )
    cdo -s sub -mulc,86400 $prfile $eptfile $wbfile
    ncrename -v pr,wb $wbfile
    ncatted -h -a units,wb,o,c,'mm d-1' $wbfile
    ncatted -h -a standard_name,wb,o,c,"water_balance" $wbfile
    ncatted -h -a long_name,wb,o,c,"water balance based on rainfall and potential evapotranspiration after Hargreaves and Samani (1985)" $wbfile
fi

## model runs
for method in $methods ; do
    for model in SMHI-EC-EARTH SMHI-RCA4 UCAN-WRF341G UL-IDL-WRF360D DWD-CCLM4-8-21 ecmwf-system4 ; do
    # for model in ecmwf-system4 ; do
        echo $model $method
        modpath=/store/msclim/bhendj/EUPORIAS/$model/$grid/daily
        eptfiles=$( \ls $modpath/ept/$method/*.nc )
        for ept in $eptfiles ; do
            pr=$( echo $ept | sed 's/ept/pr/g' )
            if [[ -f $pr ]] ; then
                wb=$( echo $ept | sed 's/ept/wb/g' )
                if [[ ! -f $wb ]] ; then
                    mkdir -p $( dirname $wb )
                    cdo -s sub -mulc,86400 $pr $ept $wb
                    ncrename -v pr,wb $wb
                    ncatted -h -a units,wb,o,c,'mm d-1' $wb
                    ncatted -h -a standard_name,wb,o,c,"water_balance" $wb
                    ncatted -h -a long_name,wb,o,c,"water balance based on rainfall and potential evapotranspiration after Hargreaves and Samani (1985)" $wb

                fi
            fi
        done
    done
done
