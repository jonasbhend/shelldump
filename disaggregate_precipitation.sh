#!/bin/bash

## simple script with cdo and nco commands to 
## compute disaggregated precipitation from accumulated precip               
this_path=$(readlink -f $0)        ## Path of this file including filename
dir_name=`dirname ${this_path}`    ## Dir where this file is
myname=`basename ${this_path}`     ## file name of this script.
gpath=/store/msclim/bhendj/EUPORIAS/grids

function usage {
  echo "
  usage: $myname infile outfile

  infile       path to input file
  outfile      path to output file"
  exit 1
}

if [[ $# != 2 ]] ; then
    usage
fi

infile=$1
outfile=$2
f=$(basename $infile)

varname=$(cdo -s showvar $infile | sed 's/ //g')

## check that accumulated precip is strictly increasing
cdo -s -L mergetime -seltimestep,1 $infile -runmax,2 $infile $SCRATCH/$f

## compute disaggregated rainfall series using runstd
cdo -s -L mergetime -seltimestep,1 $SCRATCH/$f -mulc,2 -runstd,2 $SCRATCH/$f $SCRATCH/$f.tmp

## fix time dimensions (messed up by disaggregation)
ncrename -O -h -v time,time2 $SCRATCH/$f.tmp $SCRATCH/$f
ncks -A -v time $infile $SCRATCH/$f
ncks -O -x -v time2 $SCRATCH/$f $outfile
ncatted -h -a long_name,$varname,o,c,"total precipitation" $SCRATCH/$f


rm $SCRATCH/$f $SCRATCH/$f.tmp

exit