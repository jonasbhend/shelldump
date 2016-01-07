#!/usr/local/bin/bash

dpath=/store/msclim/bhendj/EUPORIAS
index=$1
basevar=$2
grid=$3
obs=$4
flag=$5

fpath=$dpath/$obs/$grid/daily/$basevar
outpath=$dpath/$obs/$grid/monthly/$index
if [[ ! -f $outpath ]] ; then
    mkdir -p $outpath
fi

## get file names
files=$(\ls $fpath/*.nc)
## loop through files
for f in $files ; do
    nyear=$( cdo -s showyear $f | wc -w )
    ndate=$( cdo -s showdate $f | wc -w )
    if [[ $ndate -gt 50*$nyear ]] ; then
        $HOME/code/compute_indices_from_daily_series.sh $f $outpath/${index}_$(basename $f) $index $basevar $flag
    fi
done

exit
# 
# sbatch_run_compute_indices.sh ends here
