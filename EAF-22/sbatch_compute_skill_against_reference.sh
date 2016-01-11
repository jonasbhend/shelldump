#!/bin/bash

for method in fastqqmap_????-????_WFDEI none ; do
    for model in DWD-CCLM4-8-21 UCAN-WRF341G UL-IDL-WRF360D SMHI-RCA4 ecmwf-system4 ; do
        for varname in ept wb tasmax tasmin pr ; do
            outfile=/store/msclim/bhendj/EUPORIAS/skill_against_reference/EAF-22/seasonal/$varname/${varname}_${method}_${model}-ref-SMHI-EC-EARTH_vs_WFDEI_1991-2012_initmon05.nc
            if [[ ! -f $outfile ]] ; then
                sbatch --job-name="${varname}-${model}-${method}" -t 05:00:00 --mem=12GB --parsable -o ${varname}-${model}-${method}-EAF-22-initmon05_%j.log --mail-type=FAIL --mail-user=jonas.bhend@meteoswiss.ch -N 1 --cpus-per-task=1 -p postproc /users/bhendj/code/wrapper_jobscript.sbatch srun Rscript /users/bhendj/R/sbatch_skill_against_reference.R $model SMHI-EC-EARTH WFDEI $varname EAF-22 $method 05 TRUE FALSE FALSE
            fi
        done
    done
done

