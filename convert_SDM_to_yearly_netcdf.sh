#!/bin/bash

## script to convert the statistical downscaling files to yearly
## files like the ones downloaded from ECMWF

TMPDIR=$SCRATCH/SDM_$$
if [[ ! -f $TMPDIR ]] ; then
    mkdir -p $TMPDIR
fi

varname=$( echo $f | sed 's/_.*//g' )

for ((i=0; i<=30; i++)) ; do
    ncks -O -d run,$i,$i $f $TMPDIR/tmp.nc
    ## get time increment for specific forecast run
    timeinc=$( ncdump -v run $TMPDIR/tmp.nc | grep "run =" | tail -1 | sed -e "s/.*run = //g" -e "s/ ;.*//g" )
    ncwa -a run $TMPDIR/tmp.nc $TMPDIR/$f.tmp$i
    ncks -O -h -x -v run $TMPDIR/$f.tmp$i $TMPDIR/tmp.nc
    ncatted -h -a coordinates,$varname,d,, $TMPDIR/tmp.nc
    ncrename -d rlat,lat -d rlon,lon $TMPDIR/tmp.nc
    ncpdq -O -h -a time,member,lat,lon $TMPDIR/tmp.nc $TMPDIR/$f.tmp$i
    ncap2 -O -h -s "time=time + $timeinc" $TMPDIR/$f.tmp$i $TMPDIR/tmp.$f.$i

done

