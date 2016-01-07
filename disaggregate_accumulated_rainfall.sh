#!/bin/bash

dpath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4
origpath=/store/msclim/Prediction/Seasonal/ecmwf-system4/daily/global/Data_from_APN
gpath=/store/msclim/bhendj/EUPORIAS/grids
TMPDIR=$SCRATCH/tmp$RANDOM
mkdir $TMPDIR


for f in $origpath/*/seasfc_tp_??????????.nc ; do

  fname=$( basename $f )
  ofname=$( echo $fname | sed -e "s/seasfc_tp_//g" -e "s/00.nc/_pr_global2_none.nc/g" )
  outfile=$dpath/global2/daily/pr/none/$ofname
  echo $fname $ofname
  
  ## check that accumulated precip is strictly increasing
  cdo -s -L mergetime -seltimestep,1 $f -runmax,2 $f $TMPDIR/$fname
  
  ## compute disaggregated rainfall series using runstd
  cdo -s -L mergetime -seltimestep,1 $TMPDIR/$fname -mulc,2 -runstd,2 $TMPDIR/$fname $TMPDIR/$ofname
  
  cdo -s setgrid,$gpath/global2.grid -invertlat $TMPDIR/$ofname $outfile
  ncrename -h -d epsd_1,epsd -v epsd_1,epsd $outfile
  ncrename -h -v TOT_PREC,pr $outfile
  ncatted -h -a long_name,pr,o,c,"total precipitation" $outfile

  rm $TMPDIR/$fname $TMPDIR/$ofname

done

rm -rf $TMPDIR

exit


