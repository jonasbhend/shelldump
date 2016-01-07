#!/bin/bash

tmppath=/store/msclim/bhendj/EUPORIAS/tmp/
cd $tmppath

## Use sftp manually to download daily netcdf from SMHI.
## login: sftp sm_euporias_sftp@bi.nsc.liu.se
## cd euporias/WP21
## lcd RCM/EAF-22/day
## mget -a RCM/*/EAF-22/netcdf/*/*/day/tasm*.nc
## mget -a RCM/*/EAF-22/netcdf/*/*/day/pr_*.nc
## # also get the fixed info
## lcd ../fx
## mget RCM/*/EAF-22/fx/*.nc


TMPDIR=$SCRATCH/RCM_$RANDOM
mkdir $TMPDIR


## This is the automated script to reformat the NetCDFs for ease of processing
## procedure:
## 1. collate all ensemble members per year to single file
## 2. fix grid and dimensions
## 3. move into directory tree

grid=EAF-22
varnames="pr tasmax tasmin"
models="UCAN-WRF341G SMHI-RCA4 DWD-CCLM4-8-21 UL-IDL-WRF360D SMHI-EC-EARTH"
for varname in $varnames ; do
    echo $varname
    for model in $models ; do

        if [[ "$model" == "SMHI-EC-EARTH" ]] ; then
            cd $tmppath/GCM/$grid/day
        else
            cd $tmppath/RCM/$grid/day
        fi
        echo $model
        year=1979
        while [[ $year -lt 2016 ]] ; do
            let year=year+1
            echo $year
            ff1="${varname}_${grid}_SMHI-EC-EARTH_seasonal${year}0501_"
            ff2="_${model}_v1_day_${year}0501-${year}09??.nc"

            if [ -f ${ff1}r1i1p1${ff2} ] ; then
                nfiles1=$( \ls ${ff1}r?i1p1${ff2} | wc -c )
                nfiles2=$( \ls ${ff1}r*i1p1${ff2} | wc -c )
                if [[ $nfiles1 == $nfiles2 ]] ; then
                    files="${ff1}r?i1p1${ff2}"
                else
                    files="${ff1}r?i1p1${ff2} ${ff1}r??i1p1${ff2}"
                fi
                echo $files
                startrip=$(echo $files | sed -e "s/_${model}_v1.*//g" -e 's/.*0501_//g')
                endrip=$(echo $files | sed -e 's/.*0501_//g' -e 's/_.*//g')
                
                outfile=${ff1}${startrip}-${endrip}${ff2}
                
                ## collate to file
                ncecat -h -O -u number $files $TMPDIR/$outfile
                ncatted -h -a coordinates,${varname},d,, $TMPDIR/$outfile    
                ncatted -h -a grid_mapping,${varname},d,, $TMPDIR/$outfile 
                ncatted -h -a ensemble_members,global,o,c,"$startrip-$endrip" $TMPDIR/$outfile
                ncks -3 -h -v $varname $TMPDIR/$outfile $TMPDIR/$outfile.tmp
                ncpdq -h -O -a time,number,rlat,rlon $TMPDIR/$outfile.tmp $TMPDIR/$outfile
                ncrename -h -d rlon,lon -v rlon,lon -d rlat,lat -v rlat,lat $TMPDIR/$outfile
                ncatted -h -a long_name,lon,o,c,'longitude' $TMPDIR/$outfile
                ncatted -h -a long_name,lat,o,c,'latitude' $TMPDIR/$outfile
                ncatted -h -a standard_name,lon,o,c,'longitude' $TMPDIR/$outfile
                ncatted -h -a standard_name,lat,o,c,'latitude' $TMPDIR/$outfile
                ncatted -h -a units,lon,o,c,'degrees east' $TMPDIR/$outfile
                ncatted -h -a units,lat,o,c,'degrees north' $TMPDIR/$outfile
                ## ncatted -h -a long_name,number,o,c,"ensemble_member" $TMPDIR/$outfile
                ## ncatted -h -a axis,number,o,c,"Z" $TMPDIR/$outfile.tmp

                
                ## set up output directory structure
                outdir=/store/msclim/bhendj/EUPORIAS/$model/$grid/daily/$varname/none
                if [[ ! -f $outdir ]] ; then
                    mkdir -p $outdir
                fi
                
                mv $TMPDIR/$outfile $outdir/${year}0501_${varname}_${grid}_none.nc
                rm $TMPDIR/*
                
            fi
        done ## end of loop on years
    done ## end of loop on models
done ## end of loop on variable names

rmdir $TMPDIR

exit