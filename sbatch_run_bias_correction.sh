#!/usr/local/bin/bash
# sbatch_run_bias_correction.sh --- 
# 
# Filename: sbatch_run_bias_correction.sh
# Description: 
# Author: Jonas Bhend
# Maintainer: 
# Created: Tue Sep 23 11:07:50 2014 (+0200)
# Version: 
# Last-Updated: Tue Jun 16 08:20:41 2015 (+0200)
#           By: Jonas Bhend
#     Update #: 101
# URL: 
# Keywords: 
# Compatibility: 
# 
# 

# Commentary: 
# 
# 
# 
# 
grid=eobs0.44
dpath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/$grid/daily
obspath=/store/msclim/bhendj/EUPORIAS/E-OBS/$grid/daily
## obspath=/store/msclim/bhendj/EUPORIAS/ERA-INT/$grid/daily
startyear=1981
endyear=2012

## enquire current directory
curdir=`pwd`

## loop through variable name and debiasing options
for varname in tasmin  ; do
    for method in smooth smooth_scale smooth_scale-crossval1 qqmap-crossval1 ; do
        for startmon in 11 ; do
            initmon=$(printf %02d ${startmon#0})
            case $varname in
                tasmin) 
                    fcvar=Tmin 
                    obsvar=tn
                    ;;
                tasmax) 
                    fcvar=Tmax
                    obsvar=tx
                    ;;
                tas)
                    fcvar=Tavg
                    obsvar=tg
                    ;;
            esac
            
            # set directory names
            datapath=$dpath/$fcvar
            tmppath=$SCRATCH/${varname}_${method}_${startyear}-${endyear}_$RANDOM
            
            # get input files (forecasts
            infiles=`\ls $datapath/????$initmon??_??_eobs0.44.nc`
            fcfiles=''
            for f in $infiles ; do
                ff=`basename $f`
                ## exclude 2013 as observations are not yet available
                if [[ $ff != 2013* ]] ; then
                    fcfiles="$fcfiles $f"
                fi
            done
            
            # get observation file
            if \ls $obspath/$varname/${obsvar}_0.44deg_rot_v10.0.nc 2> /dev/null ; then
                obsfiles=`\ls $obspath/$varname/${obsvar}_0.44deg_rot_v10.0.nc`
            else
                obsfiles=`\ls $obspath/$varname/erainterim_${varname}*.nc`
            fi

            # set random component for batch job file
            batchfile=$HOME/logs/sbatch_bias_correct_${varname}_${method}_initmon${initmon}.sh

            ## write the batch file
            cat > $batchfile <<EOF
#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=bias_correct
#SBATCH --mail-type=FAIL
#SBATCH --time=08:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=32GB
#SBATCH --partition=postproc
#SBATCH --output=$curdir/bias_correct_${varname}_${method}_initmon${initmon}_%j.log

#======START=====
srun Rscript /users/bhendj/R/bias_correct_seasonal_forecasts.R $varname $method $startyear $endyear $fcfiles $obsfiles $dpath

EOF

            sbatch $batchfile
            rm $batchfile

        done
    done
done

exit

# 
# sbatch_run_bias_correction.sh ends here
