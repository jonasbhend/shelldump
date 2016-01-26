#!/bin/bash

## this script is used to compute snowdays and snowfall from the
## (bias corrected) forecast data of mean temperature and rainfall
## and from the corresponding verifying observations

grid=global2
fpath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/$grid


for method in fastqqmap_1981-2010_ERA-INT ; do

## compute snowdays
outdir=$fpath/monthly/snowdays/$method
if [[ ! -f $outdir ]] ; then
    mkdir -p $outdir
fi

year=1980
endyear=2014
if [[ $grid == "eobs0.44" ]] ; then
    endyear=2013
fi
while [[ $year -lt $endyear ]] ; do 
    let year=year+1 
    echo $year 
    prfile=$fpath/daily/pr/$method/${year}1101_*_${grid}_${method}.nc
    tasfile=$fpath/daily/tas/$method/${year}1101_*_${grid}_${method}.nc
    outfile=$fpath/monthly/snowdays/$method/snowdays_${year}1101_tas-pr_${grid}_${method}.nc
    echo $prfile
    echo $tasfile
    echo $outfile
    cdo -s -L divdpm -monsum -mul -setrtoc2,-1000,0.001,0,1 $prfile -setrtoc2,0,275.15,1,0 $tasfile $outfile
    ncrename -v pr,snowdays $outfile
    ncatted -h -a units,snowdays,o,c,'days/day' $outfile
    ncatted -h -a long_name,snowdays,o,c,'Fraction of days with snowfall' $outfile
done

## compute snowfall
outdir=$fpath/monthly/snowfall/$method
if [[ ! -f $outdir ]] ; then
    mkdir -p $outdir
fi

year=1980
while [[ $year -lt $endyear ]] ; do 
    let year=year+1 
    echo $year 
    prfile=$fpath/daily/pr/$method/${year}1101_*_${grid}_${method}.nc
    tasfile=$fpath/daily/tas/$method/${year}1101_*_${grid}_${method}.nc
    outfile=$fpath/monthly/snowfall/$method/snowfall_${year}1101_tas-pr_${grid}_${method}.nc
    echo $prfile
    echo $tasfile
    echo $outfile
    cdo -s -L divdpm -monsum -mulc,1000 -mul -setrtoc,-1000,0.001,0 $prfile -setrtoc2,0,275.15,1,0 $tasfile $outfile
    ncrename -v pr,snowfall $outfile
    ncatted -h -a units,snowfall,o,c,'cm/day' $outfile
    ncatted -h -a long_name,snowfall,o,c,'Average snowfall per day' $outfile
done

done ## end of loop on methods

exit

## compute the snowfall and snowdays indices for the observations
if [[ $grid == "eobs0.44" ]] ; then
opath=/store/msclim/bhendj/EUPORIAS/E-OBS/$grid
tasfile=$opath/daily/tas/tg_0.44deg_rot_v11.0.nc
prfile=$opath/daily/pr/rr_0.44deg_rot_v11.0.nc
else 
opath=/store/msclim/bhendj/EUPORIAS/ERA-INT/$grid
tasfile=$opath/daily/tas/erainterim_tas_1981-2014.nc
prfile=$opath/daily/pr/erainterim_pr_1981-2014.nc
fi

varname=snowdays
outdir=$opath/monthly/$varname
if [[ ! -f $outdir ]] ; then
    mkdir -p $outdir
fi

if [[ $grid == "eobs0.44" ]] ; then
    outfile=$outdir/${varname}_0.44deg_rot_v11.0_tas-pr_1981-2014.nc
    cdo -b 32 -s -L divdpm -monsum -mul -setrtoc2,-1000,1,0,1 $prfile -setrtoc2,-273.15,2,1,0 $tasfile $outfile
    ncrename -v rr,$varname $outfile
else 
    outfile=$outdir/${varname}_erainterim_tas-pr_1981-2014.nc
    cdo -s -L divdpm -monsum -mul -setrtoc2,-1000,0.001,0,1 $prfile -setrtoc2,0,275.15,1,0 $tasfile $outfile
    ncrename -v pr,$varname $outfile
fi 
ncatted -h -a units,$varname,o,c,'days/day' $outfile
ncatted -h -a long_name,$varname,o,c,'Fraction of days with snowfall' $outfile

varname=snowfall
outdir=$opath/monthly/$varname
if [[ ! -f $outdir ]] ; then
    mkdir -p $outdir
fi

if [[ $grid == "eobs0.44" ]] ; then
    outfile=$outdir/${varname}_0.44deg_rot_v11.0_tas-pr_1981-2014.nc
    cdo -b 32 -s -L divdpm -monsum -mul -setrtoc,-1000,1,0 $prfile -setrtoc2,-273.15,2,1,0 $tasfile $outfile
    ncrename -v rr,$varname $outfile
else 
    outfile=$outdir/${varname}_erainterim_tas-pr_1981-2014.nc
    cdo -s -L divdpm -monsum -mulc,1000 -mul -setrtoc,-1000,0.001,0 $prfile -setrtoc2,0,275.15,1,0 $tasfile $outfile
    ncrename -v pr,$varname $outfile
fi
ncatted -h -a units,$varname,o,c,'cm/day' $outfile
ncatted -h -a long_name,$varname,o,c,'Average snowfall per day' $outfile

 


