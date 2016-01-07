#!/usr/local/bin/bash

dpath=/store/msclim/bhendj/EUPORIAS
model=$1
index=$2
basevar=$3
grid=$4
method=$5
init=$(printf %02d ${6#0})
flag=$7

## get file names
files=$(\ls $dpath/$model/$grid/daily/$basevar/$method/????${init}??_*.nc) 

## check that files exist
if [[ ! -f $( echo $files | sed 's/ .*//g') ]] ; then
    exit 1
fi

fpath=$( dirname $( echo $files | sed 's/ .*//g'))
if [[ -d $fpath ]] ; then
    method=$(basename $fpath)
else 
    exit 1
fi

outpath=$dpath/$model/$grid/monthly/$index/$method
if [[ ! -f $outpath ]] ; then
    mkdir -p $outpath
fi

## loop through files
for f in $files ; do
    nyear=$( cdo -s showyear $f | wc -w )
    ndate=$( cdo -s showdate $f | wc -w )
    ## check that these are daily series
    if [[ $ndate -gt 50*$nyear ]] ; then
    $HOME/code/compute_indices_from_daily_series.sh $f $outpath/${index}_$(basename $f) $index $basevar $flag
    fi
done

exit
# 
# sbatch_run_compute_indices.sh ends here
