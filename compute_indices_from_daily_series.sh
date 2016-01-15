#!/bin/bash
# compute_indices_from_daily_series.sh --- 
# 
# Filename: compute_indices_from_daily_series.sh
# Description: 
# Author: Jonas Bhend
# Maintainer: 
# Created: Tue Sep 23 09:35:13 2014 (+0200)
# Version: 
# Last-Updated: Fri Jan 15 15:21:47 2016 (+0100)
#           By: Jonas Bhend
#     Update #: 194
# URL: 
# Keywords: 
# Compatibility: 
# 
# 

# Commentary: 
#   This script is used to compute indices (e.g. HDD) from daily time
#   series using CDOs. The daily time series are split to monthly files
#   on which the corresponding index is computed. The results are then
#   merged to contain the original time period (e.g. 7 months) in one
#   file.

nargs=5
function usage {
    echo "USAGE: $0 infile outfile index varname offset"
    echo "    infile:     Input file with daily time series"
    echo "    outfile:    Output file with monthly series of indices"
    echo "    index:      Climate information index"
    echo "    varname:    Variable name [tasmin|tasmax|tas|pr] for consistency checks"
    echo "    offset:     offset for time axis [true|false]"
    echo ""

    echo "The time axis offset is needed for forecasts of Tmin and Tmax"
    echo "as these refer to the 24-hour period before the timestamp. If"
    echo "the offset is set to true, the time axis is shifted by 12 hours"
    echo "previous to computing the climate indices."

    exit 1
}

if [ $# -eq $nargs ] ; then
    infile=$1
    outfile=$2
    index=$3
    varname=$4
    offset=$5
else
  usage
fi


## check for consistency (HDD with tas, FD with tasmin, etc.)
if [[ ( $index == "HDD" || $index == "HDDch" || $index == "ITV" || $index == "HeatingDay" || $index == "CoolingDay" ) && $varname != "tas" ]] ; then
  echo "Trying to compute HDD/ITV with something else than daily mean temperature"
  exit
elif [[ $index == "FD" && $varname != "tasmin" ]] ; then
  echo "Trying to compute FD with something else than daily minimum temperature"
  exit
elif [[ $index == "CDD" && $varname != "tas" ]] ; then
  echo "Trying to compute CDD with something else than daily mean temperature"
  exit  
elif [[ ( $index == "HD" || $index == "SD" ) && $varname != "tasmax" ]] ; then
  echo "Trying to compute HD or SD with something else than daily maximum temperature"
  exit
fi



## get file name stems etc.
ifile=`basename $infile`
ifilestem=`echo $ifile | sed 's/.nc/_/g'`
ofile=`basename $outfile`
outpath=`echo $outfile | sed "s/$ofile//g"`
if [[ $outpath == "" ]] ; then
  outpath=`pwd`
fi

## set up temporary directory
TMPDIR=$SCRATCH/${index}_$RANDOM
mkdir -p $TMPDIR
## set up output file path
mkdir -p $outpath

## convert units if needed
unit=`cdo -s showunit $infile | sed 's/ //g'`
tmpfile=$TMPDIR/$ifile
if [[ $varname == "pr" ]] ; then
    if [[ $offset == "true" ]] ; then
        cdo -s shifttime,-12hours $infile $tmpfile
    else 
        tmpfile=$infile
    fi
else  
    if [[ $offset == "true" ]] ; then
        if [[ $varname =~ "tas" && $unit != "K" ]] ; then
            cdo -s shifttime,-12hours -addc,273.15 $infile $tmpfile
        else
            cdo -s shifttime,-12hours $infile $tmpfile
        fi
    elif [[ $unit != "K" && $offset != "true" && $varname =~ "tas" ]] ; then
        cdo -s addc,273.15 $infile $tmpfile
    else
        tmpfile=$infile 
    fi
fi

## initialise commands to compute index
case $index in
    HDD) cdoarg="eca_hd,17" ;;
    HDDch) cdoarg="eca_hd,18,12" ;;
    HeatingDay) cdoarg="muldpm -timavg -setrtoc2,0,290.15,1,0" ;;
    CoolingDay) cdoarg="muldpm -timavg -setrtoc2,0,295.15,0,1" ;;
    FD) cdoarg="eca_fd" ;;
    CDD) cdoarg="eca_hd,0 -addc,273.15 -mulc,-1 -subc,295.15" ;;
    $varname) cdoarg="muldpm -timavg" ;;
    logpr) cdoarg="log -addc,0.001 -timsum" ;;
    WDF) cdoarg="muldpm -timavg -setrtoc2,-1e4,0.001,0,1" ;; 
    ITV) cdoarg="muldpm -timavg -mulc,2 -runstd,2" ;; 
    SD) cdoarg="eca_su,25" ;;
    HD) cdoarg="eca_su,30" ;;
    *PDD*|*NDD*|*PCC*|*NCC*) 
        pctl=$(echo $index | sed -e 's/.*DD//g' -e 's/.*CC//g' )
        grid=$(echo $infile | sed -e 's_/daily.*__g' -e 's_.*/__g' )
        if [[ $index =~ "seas" ]] ; then
            pctlfile=$(\ls /store/msclim/bhendj/EUPORIAS/[EG]*/$grid/fx/$varname/seaspctl${pctl}_*.nc)
        else
            pctlfile=$(\ls /store/msclim/bhendj/EUPORIAS/[EG]*/$grid/fx/$varname/pctl${pctl}_*.nc)
        fi
        echo $pctlfile
        if [[ ! -f $pctlfile ]] ; then
            exit 1
        fi
        ## check on number of ensemble members
        #1. get number of dimensions
        vn=$(cdo -s showvar $tmpfile | sed 's/ //g')
        ndims=$(ncdump -c $tmpfile | grep " $vn" | grep -E "(epsd|number)" | wc -l)
        ## change the dimensionality of pctlfile
        if [[ $ndims == 1 ]] ; then
            enspctlfile=${pctlfile/pctl/enspctl}
            if [[ ! -f $enspctlfile ]] ; then
                cdo -s setgrid,$infile $pctlfile $TMPDIR/$(basename $pctlfile)
                pctlfile=$TMPDIR/$(basename $pctlfile)
                let i=0
                while [[ $i -lt 51 ]] ; do
                    let i=i+1
                    ln -s $pctlfile $pctlfile.$i
                done
                ncecat -h -O $pctlfile.* $pctlfile.tmp
                ncpdq -O -a time,record $pctlfile.tmp $enspctlfile
                rm $pctlfile.*
            fi
            pctlfile=$enspctlfile
        else 
            ## regrid the pctlfile
             cdo -s setgrid,$infile $pctlfile $TMPDIR/$(basename $pctlfile)
             pctlfile=$TMPDIR/$(basename $pctlfile)
        fi
       ;;
esac


## find out whether the file contains more than one year
years=`cdo -s showyear $tmpfile`
years=( $years )
nyears=${#years[@]}
if [[ $nyears -gt 2 ]] ; then
    ## first split by years
    cdo -s splityear $tmpfile $TMPDIR/$ifilestem
    for f in $TMPDIR/${ifilestem}????.nc ; do
        ## then split by months
        cdo -s splitmon $f ${f/.nc/}
    done
    ## then remove all the yearly files (and retain year-monthly only)
    rm $TMPDIR/${ifilestem}????.nc
else
    ## extract monthly data 
    cdo -s splitmon $tmpfile $TMPDIR/$ifilestem
fi


## compute index on monthly files
monfiles=`\ls $TMPDIR/${ifilestem}??*.nc`
for f in $monfiles ; do
    if [[ $index =~ "PDD" ]] ; then
        cdo -b 32 -L -s timsum -setrtoc,-1e20,0,0 -ydaysub $f $pctlfile ${f/$ifilestem/$index}
    elif [[ $index =~ "NDD" ]] ; then
        cdo -b 32 -L -s timsum -mulc,-1 -setrtoc,0,1e20,0 -ydaysub $f $pctlfile ${f/$ifilestem/$index}
    elif [[ $index =~ "PCC" ]] ; then
        cdo -b 32 -L -s timsum -gec,0 -ydaysub $f $pctlfile ${f/$ifilestem/$index}
    elif [[ $index =~ "NCC" ]] ; then
        cdo -b 32 -L -s timsum -lec,0 -ydaysub $f $pctlfile ${f/$ifilestem/$index}
    else
        ntime=$( cdo -s showdate $f | tail -1 | wc -w )
        if [[ $ntime -gt 2 ]] ; then
            cdo -b 32 -L -s $cdoarg $f ${f/$ifilestem/$index}
        else
            cdo -b 32 -L -s setrtomiss,-1e20,1e20 -timsum $f ${f/$ifilestem/$index}
        fi
    fi

    if [[ $index == "HDD" || $index == "CDD" || $index == "HDDch" || $index == "SD" || $index == "HD" ]] ; then
        mask=${f/$ifilestem/non-missing}
        zero=${f/$ifilestem/missingtozero}
        ## get non-missing positions
        cdo -L -s setrtoc,-1e20,1e20,1 -timmean $f $mask
        ## set all missing values in index to zero
        cdo -L -s setmisstoc,0 ${f/$ifilestem/$index} $zero
        ## use index where non-missing is not missing
        cdo -L -s ifthen $mask $zero ${f/$ifilestem/$index}
        ## remove the temporary files
        rm $mask $zero
    fi

    rm $f
done

## merge files to output file
cdo -s mergetime $TMPDIR/${index}*.nc $TMPDIR/$ifile
cdo -s divdpm $TMPDIR/$ifile $outfile

## change variable name for cooling degree days
if [[ $index == "CDD" ]] ; then
    ncrename -h -v heating_degree_days_per_time_period,CDD $outfile
    ncatted -h -a long_name,CDD,o,c,'Average cooling degree days per day ( > 22 deg. C)' $outfile
    ncatted -h -a units,CDD,o,c,'deg. C' $outfile
elif [[ $index == "HDD" ]] ; then
    ncrename -h -v heating_degree_days_per_time_period,HDD $outfile
    ncatted -h -a long_name,HDD,o,c,'Average heating degree days per day ( < 17 deg. C)' $outfile
    ncatted -h -a units,HDD,o,c,'deg. C' $outfile
elif [[ $index == "HDDch" ]] ; then
    ncrename -h -v heating_degree_days_per_time_period,HDDch $outfile
    ncatted -h -a long_name,HDDch,o,c,'Average heating degree days per day ( diff. to 18 deg. C for < 12 deg. C)' $outfile
    ncatted -h -a units,HDDch,o,c,'deg. C' $outfile
elif [[ $index == "SD" ]] ; then
    ncrename -h -v summer_days_index_per_time_period,SD $outfile
    ncatted -h -a long_name,SD,o,c,'Fraction of summer days (Tmax > 25 deg. C)' $outfile
elif [[ $index == "HD" ]] ; then
    ncrename -h -v summer_days_index_per_time_period,HD $outfile
    ncatted -h -a long_name,HD,o,c,'Fraction of heat days (Tmax > 30 deg. C)' $outfile
elif [[ $index =~ "PDD" || $index =~ "NDD" || $index =~ "NCC" || $index =~ "PCC" ]] ; then
    vname=`cdo -s showvar $outfile | sed 's/ //g'`
    pctl=$(echo $index | sed -e 's/.*DD//g' -e 's/.*CC//g')
    if [[ $index =~ "seas" ]] ; then
        pctl=$(echo "seasonal $pctl")
    fi
    ncrename -h -v $vname,$index $outfile
    if [[ $index =~ "PDD" ]] ; then
        ncatted -h -a long_name,$index,o,c,"Average degree days per day (> ${pctl}th percentile of ERA-INT)" $outfile
    elif [[ $index =~ "NDD" ]] ; then
        ncatted -h -a long_name,$index,o,c,"Average degree days per day (< ${pctl}th percentile of ERA-INT)" $outfile
    elif [[ $index =~ "PCC" ]] ; then
        ncatted -h -a long_name,$index,o,c,"Average number of threshold exceedances (< ${pctl}th percentile of ERA-INT)" $outfile
    elif [[ $index =~ "NCC" ]] ; then
        ncatted -h -a long_name,$index,o,c,"Average number of departures below threshold (< ${pctl}th percentile of ERA-INT)" $outfile
    fi
    if [[ $index =~ "PDD" || $index == "NDD" ]] ; then
        ncatted -h -a units,$index,o,c,"deg. C" $outfile
    else
        ncatted -h -a units,$index,o,c,"1" $outfile
    fi
else 
    vname=`cdo -s showvar $outfile | sed 's/ //g'`
    if [[ $vname != $index ]] ; then
        ncrename -h -v $vname,$index $outfile
    fi
fi

## remove the temporary directory
rm -rf $TMPDIR

exit
# 
# compute_indices_from_daily_series.sh ends here
