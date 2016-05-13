#!/bin/bash

tmppath=/store/msclim/bhendj/tmp
cd $tmppath

for grid in global2 eobs0.44 ; do
    
    case $grid in
        global2)
            egrid=global
            ;;
        eobs0.44)
            egrid=eobs
            ;;
    esac

    for varname in tas tasmax tasmin pr ; do

        outdir=/store/msclim/bhendj/EUPORIAS/ERA-INT/$grid/daily/$varname

        case $varname in 
            tas)
                epar=167
                vname=t2m
                ;;
            tasmax)
                epar=201
                vname=mx2t
            ;;
            tasmin)
                epar=202
                vname=mn2t
            ;;
            pr)
                epar=228
                vname=tp
                ;;
        esac

        cdo -s -r mergetime eraint_${epar}_*-*_${egrid}.nc $outdir/erainterim_${varname}_1981-2015.nc
        ncrename -v $vname,$varname $outdir/erainterim_${varname}_1981-2015.nc
        


    done
done