#!/bin/bash

## this script copies and renames the files from APN on the global grid
## also it will disaggregate accumulated precipitation

grid=global2
apath=/store/msclim/Prediction/Seasonal/ecmwf-system4/daily/global/Data_from_APN
dpath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/$grid/daily
tpath=/store/msclim/bhendj/tmp
opath=/store/msclim/Prediction/ERAINTERIM
oopath=/store/msclim/bhendj/EUPORIAS/ERA-INT/$grid/daily
gpath=/store/msclim/bhendj/EUPORIAS/grids

for varname in pr ; do
    echo "Run computation for $varname"

    if [[ ! -f $dpath/$varname/none ]] ; then
        mkdir -p $dpath/$varname/none
    fi
    
    case $varname in
        tasmin | tas ) basevar=mn2t24 ;;
        tasmax ) basevar=mx2t24 ;;
        pr ) basevar=tp ;;
    esac
    if [[ $varname == 'pr' ]] ; then
        upperbase=TOT_PREC
    else
        upperbase=$(echo $basevar | tr -s '[:lower:]' '[:upper:]' )
    fi

    if [[ $varname == "tas" ]] ; then
        ## compute daily mean temperature from minimum and maximum
        cd $apath
        minfiles=$(\ls */seasfc_mn2t24_*.nc)
        for minf in $minfiles ; do
            maxf=${minf/mn2t24/mx2t24}
            odate=$( echo $minf | sed -e "s/.*_//g" -e "s/00.nc//g")
            ofile=${odate}_${varname}_${grid}_none.nc
            cdo -s -r setgrid,$gpath/$grid.grid -invertlat -divc,2 -add $apath/$minf $apath/$maxf $dpath/$varname/none/$ofile
            ncrename -h -d epsd_1,epsd -v epsd_1,epsd $dpath/$varname/none/$ofile
            ncrename -h -v $upperbase,$varname $dpath/$varname/none/$ofile
        done

    else

        cd $apath
        files=$(\ls */seasfc_${basevar}_*.nc)
        for f in $files ; do
        ## echo $f
            odate=$( echo $f | sed -e "s/.*_//g" -e "s/00.nc//g")
        ## echo $odate
            ofile=${odate}_${varname}_${grid}_none.nc
            if [[ $varname == "pr" ]] ; then
                ## check that accumulated precip is strictly increasing
                cdo -s -L mergetime -seltimestep,1 $f -runmax,2 $f $SCRATCH/$f
  
                ## compute disaggregated rainfall series using runstd
                cdo -s -L mergetime -seltimestep,1 $SCRATCH/$f -mulc,2 -runstd,2 $SCRATCH/$f $SCRATCH/$f.tmp
                
                cdo -s setgrid,$gpath/global2.grid -invertlat $SCRATCH/$f.tmp $dpath/$varname/none/$ofile
                ncatted -h -a long_name,$upperbase,o,c,"total precipitation" $dpath/$varname/none/$ofile
                
                ## fix time dimensions (messed up by disaggregation)
                ncrename -h -v time,time2 $dpath/$varname/none/$ofile $SCRATCH/$f
                ncks -A -v time $f $SCRATCH/$f
                ncks -O -x -v time2 $SCRATCH/$f $dpath/$varname/none/$ofile

            else
                cdo -s setgrid,$gpath/$grid.grid -invertlat $apath/$f $dpath/$varname/none/$ofile
            fi
            ncrename -h -d epsd_1,epsd -v epsd_1,epsd $dpath/$varname/none/$ofile
            ncrename -h -v $upperbase,$varname $dpath/$varname/none/$ofile
        done

    fi
done

# ## also add the observations (copy and concatenate)
# for varname in tas tasmax tasmin pr ; do

#     if [[ ! -f $oopath/$varname ]] ; then
#         mkdir -p $oopath/$varname
#     fi

#     if [[ $varname == "tas" ]] ; then
#         cdo -s -r mergetime $opath/tas/daily/erainterim_tas_????.nc $oopath/$varname/erainterim_${varname}_1981-2013.nc 
#         ncrename -h -v t2m,$varname $oopath/$varname/erainterim_tas_1981-2013.nc
#     elif [[ $varname == "tasmax" ]] ; then
#         cdo -s -r mergetime $opath/tas_max/daily/????_daymax.nc $oopath/$varname/erainterim_${varname}_1981-2012.nc
#         ncrename -h -v mx2t,$varname $oopath/$varname/erainterim_${varname}_1981-2012.nc
#     elif [[ $varname == "tasmin" ]] ; then
#         cdo -s -r mergetime $opath/tas_min/daily/????_daymin.nc $oopath/$varname/erainterim_${varname}_1981-2012.nc
#         ncrename -h -v mn2t,$varname $oopath/$varname/erainterim_${varname}_1981-2012.nc
#     elif [[ $varname == "pr" ]] ; then
#         cdo -s -r remapcon2,$gpath/$grid.grid $opath/$varname/daily/erainterim_pr_1979-2012_daily_12.nc $oopath/$varname/erainterim_${varname}_1979-2013.nc
#         ncrename -h -v tp,$varname $oopath/$varname/erainterim_${varname}_1979-2013.nc
#     fi

# done



