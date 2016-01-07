#! /bin/bash

## this script is used to compute tmin and tmax from 3-hourly 
## surface air temperature of WFDEI

datapath=/store/msclim/Prediction/WFDEI

TMPDIR=$SCRATCH/WFDEI_$RANDOM
mkdir -p $TMPDIR

if [[ ! -f $datapath/tasmax_daily_WFDEI ]] ; then
    mkdir $datapath/tasmax_daily_WFDEI
fi

if [[ ! -f $datapath/tasmin_daily_WFDEI ]] ; then
    mkdir $datapath/tasmin_daily_WFDEI
fi


cd $datapath
for f in Tair_WFDEI/*.nc.gz ; do
    echo $f
    ff=$(basename ${f/.gz/})
    tmax=${ff/Tair/tasmax}
    tmin=${ff/Tair/tasmin}

    cp $f $TMPDIR
    gunzip $TMPDIR/$ff.gz
    
    ## fix missing value attribute
    ncatted -h -a Fill_value,Tair,d,, $TMPDIR/$ff
    ncatted -h -a _FillValue,Tair,a,f,1e20 $TMPDIR/$ff

    ## compute daily minimum and maximum temperature
    cdo -s daymin $TMPDIR/$ff $datapath/tasmin_daily_WFDEI/${ff/Tair/tasmin}
    cdo -s daymax $TMPDIR/$ff $datapath/tasmax_daily_WFDEI/${ff/Tair/tasmax}
    
    ncrename -h -v Tair,tasmin $datapath/tasmin_daily_WFDEI/${ff/Tair/tasmin}
    ncrename -h -v Tair,tasmax $datapath/tasmax_daily_WFDEI/${ff/Tair/tasmax}

    ## compress files
    gzip $datapath/tasmin_daily_WFDEI/${ff/Tair/tasmin}
    gzip $datapath/tasmax_daily_WFDEI/${ff/Tair/tasmax}

    rm $TMPDIR/$ff

done

rm -rf $TMPDIR
exit