#!/bin/bash

## this script lets you complete forecast indices that have not
## been fully run due to time or else

if [[ $# -lt 4 ]] ; then
    echo "usage: complete_indices.sh startyear index method initmon"
    echo ""
    echo "    startyear   first year to be run"
    echo "    index       index to be completed (e.g. NDD01)"
    echo "    method      bias correction method (e.g. smooth-scale)"
    echo "    initmon     initialization month (e.g. 11)"
fi

startyear=$1
index=$2
method=$3
initmon=$4



year=$startyear
while [[ $year -lt 2015 ]] ; do 
    infile=$(\ls /store/msclim/bhendj/EUPORIAS/ecmwf-system4/global2/daily/tas/${method}_1981-2010_ERA-INT/${year}${initmon}01*.nc) 
    outfile=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/global2/monthly/$index/${method}_1981-2010_ERA-INT/${index}_$(basename $infile)
    echo ""   
    echo $infile 
    echo $outfile
    sbatch --job-name=indices -t 01:00:00 --mem=18GB --parsable -o $HOME/logs/${year}_${index}_${method}_job%j.log --mail-type=FAIL --mail-user=jonas.bhend@meteoswiss.ch -N 1 --cpus-per-task=1 -p postproc /users/bhendj/code/wrapper_jobscript.sbatch srun /users/bhendj/code/compute_indices_from_daily_series.sh $infile $outfile $index tas true
    let year=year+1 
done

exit