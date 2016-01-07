#!/usr/local/bin/bash

function usage {
    echo
    echo "usage: $(basename $0) [-fnv] [-s proc] forecast observation index grid \\"
    echo "                              [bias initmon ref.obs]"
    echo 
    echo "       -f            force update of all dependencies"
    echo "       -n            dry run without execution of batch jobs"
    echo "       -v            verbose"
    echo "       -s proc       back to which process should forec rerun be run?"
    echo "                     <proc> can be one of skill, index, or bias"
    echo "       forecast      forecasting system to be used (e.g. ecmwf-system4)"
    echo "       observation   verifying observation (e.g. E-OBS, ERA-INT)"
    echo "       index         CII to be computed (e.g. HDD, HDDch, tas, ...)"
    echo "       grid          grid specification of forecasts and obs (e.g. eobs0.44"
    echo "       bias          bias correction method (e.g. qqmap, smooth-crossval1)"
    echo "       initmon       month of forecast initialisation (1-12)"
    echo "       ref.obs       reference observation for debiasing (e.g. E-OBS, ERA-INT, if not set, is the same as obs.)"
    echo
    
    exit 1
}

comparedate () {
    childtree=$1
    parenttree=$2
    
    if \ls $childtree &> /dev/null && \ls $parenttree &> /dev/null  ; then
        childtimes=$( stat -c "%Z" $childtree )
        ## echo $childtimes
        childtime=$( echo $childtimes | head -1 | awk '{print $1}')
        for ct in $childtimes ; do
            if [[ $ct -lt $childtime ]] ; then
                childtime=$ct
            fi
        done
        ## echo "Max Childtime: $childtime"
    

        parenttimes=$( stat -c "%Z" $parenttree )
        ## echo $parenttimes
        parenttime=$( echo $parenttimes | head -1 | awk '{print $1}')
        for pt in $parenttimes ; do
            if [[ $pt -gt $parenttime ]] ; then
                parenttime=$pt
            fi
        done
        ## echo "Max Parenttime: $parenttime"
        
        
        if [[ $childtime -lt $parenttime ]] ; then
            return=1
        ## child is older than parent
        else
            return=0
        fi
    else
        return=1
    fi

    
    echo $return
}


NO_ARGS=3
E_OPTERROR=85

## get options
force=0
dry=0
verbose=0
stop=bias ## set process option if not set
while getopts s:fvnh Option ; do
  case $Option in
      s ) stop=${OPTARG} ;;
      f ) force=1 ;;
      n ) dry=1 ;;
      v ) verbose=1 ;;
      * ) usage ;;
  esac
done

## decrement argument pointer
shift $(($OPTIND - 1))

## check command-line arguments
if [ $# -lt "$NO_ARGS" ] ; then
    usage
fi

## get input variables
model=$1
obs=$2
index=$3
grid=$4
if [ $# -gt 4 ] ; then
    bias=$5
else
    bias=none
fi
if [ $# -gt 5 ] ; then
    init=$(printf %02d ${6#0})
else
    init=11
fi
if [ $# -gt 6 ] ; then
    robs=$7
else 
    robs=$obs
fi


years="????-????"
if [[ $bias =~ "none" ]] ; then
    method=$bias
else
    method=${bias}_${years}_${robs}
fi

## figure out base variable
case $index in
    tas|HDD|HDDch|CDD|ITV|*NDD*|*PDD*|*NCC*|*PCC*|CoolingDay|HeatingDay ) basevar=tas ;;
    tasmin|FD ) basevar=tasmin ;;
    tasmax|HD|SD ) basevar=tasmax;;
    dtr ) basevar=dtr ;; 
    pr|logpr|WDF ) basevar=pr ;; 
    snowfall|snowdays ) basevar=tas-pr ;;
    * )  echo "Index not implemented yet"
        exit 1;;
esac

if [[ ! "skill index obsindex bias write" =~ $stop ]] ; then
    echo "argument $s for option -s not known"
    exit 1
fi


## Initial output
if [ $verbose == 1 ] ; then
    echo 
    echo "*************************************************************************"
    echo "Run the script for"
    echo "    forecast:         $model"
    echo "    observation:      $obs"
    echo "    index:            $index"
    echo "    grid:             $grid"
    echo "    reference obs:    $robs"
    echo "    bias correction:  $bias"
    echo "    initialisation:   $init"
    echo "    base variable:    $basevar"

    if [ $force  == 1 ] ; then
        echo "    Force update all dependencies"
    fi
    if [ $dry == 1 ] ; then
        echo "    Dry run"
    fi
fi

## file paths for forecast files
dpath=/store/msclim/bhendj/EUPORIAS
datapath=$dpath/$model/$grid/daily/$basevar/none
if [[ $bias =~ "none" ]] ; then
    biaspath=$datapath
    indexpath=$dpath/$model/$grid/monthly/$index/none
else
    biaspath=$dpath/$model/$grid/daily/$basevar/$method
    indexpath=$dpath/$model/$grid/monthly/$index/$method
fi

## file paths for observations
obspath=$dpath/$obs/$grid/daily/$basevar
oindexpath=$dpath/$obs/$grid/monthly/$index

## bias correction files
biasfiles="$biaspath/????${init}01_${basevar}_${grid}_${method}*.nc"
origfiles="$datapath/????${init}01_${basevar}_${grid}_none.nc"
nbias=$( \ls $biasfiles 2> /dev/null | wc -w )

## obsindex files
obsorig="$obspath/*.nc"
obsfiles="$oindexpath/${index}_*.nc"
nobs=$( \ls $obsfiles 2> /dev/null | wc -w )

## index files
indexfiles="$indexpath/${index}_????${init}01_*${grid}_*.nc"
nindex=$( \ls $indexfiles 2> /dev/null | wc -w )

## skill scores
## file paths for skill scores
spath=$dpath/skill_scores/$grid
skillpath=$dpath/skill_scores/$grid/*/$index
skillfiles="$skillpath/${index}_*${method}_${model}_vs_${obs}_${years}_initmon$init.nc"
nskill=$( \ls $skillfiles 2> /dev/null | wc -w )

## forecasts
## file paths for forecasts
fpath=$dpath/forecasts/$model/$grid
fcstpath=$dpath/forecasts/$model/$grid/seasonal/$index
fcstfiles="$fcstpath/$method/${index}*${grid}_*initmon${init}/${index}*${grid}*initmon${init}_????_???.Rdata"
nfcst=$( \ls $fcstfiles 2> /dev/null | wc -w )


## determine what parts of the computation are required
##############################################################################

if [[ $force == 1 ]] ; then
    compute_skill=1
    write_forecasts=1
    if [[ $stop == "write" ]] ; then
        compute_skill=0
    elif [[ $stop == "skill" ]] ; then
        compute_fcindex=0
        compute_obsindex=0
    elif [[ $stop == 'index' ]] ; then
        compute_fcindex=1
        compute_obsindex=0
    elif [[ $stop == "obsindex" ]] ; then
        compute_fcindex=1
        compute_obsindex=1
    else
        compute_fcindex=1
        compute_obsindex=1
    fi
else 
    write_forecasts=0
    compute_skill=0
    compute_fcindex=0
    compute_obsindex=0
fi
## only run debiasing if needed (not for none)
compute_debias=0
    
# echo $( comparedate "$skillfiles" "$indexfiles" ) 
# echo $( comparedate "$skillfiles" "$origfiles" ) 
# echo $( comparedate "$obsfiles" "$obsorig" ) 
# echo $( comparedate "$skillfiles" "$obsfiles" )

## check if skill scores should be rerun
if [[ $nskill -lt 2 || $( comparedate "$skillfiles" "$indexfiles" ) == 1 || $( comparedate "$skillfiles" "$origfiles" ) == 1 || $( comparedate "$obsfiles" "$obsorig" ) == 1 || $( comparedate "$skillfiles" "$obsfiles" ) == 1 ]] ; then
    compute_skill=1
fi

## check if forecasts should be written to disc
if [[ $nfcst -lt 30  || $( comparedate "$fcstfiles" "$indexfiles" ) == 1 || $( comparedate "$fcstfiles" "$origfiles" ) == 1 || $( comparedate "$obsfiles" "$obsorig" ) == 1 || $( comparedate "$fcstfiles" "$obsfiles" ) == 1 ]] ; then
    write_forecasts=1
fi

## check dependencies for skill scores
if [[ $compute_skill == 1 ]] ;then

    ## check if indices need to be recomputed
    if [[ $nindex  == 0 || $( comparedate "$indexfiles" "$biasfiles" ) == 1 || $( comparedate "$indexfiles" "$origfiles" ) == 1 ]] ; then
        compute_fcindex=1
    fi

    if [[ $nobs == 0 || $( comparedate "$obsfiles" "$obsorig" ) == 1 ]] ; then
        compute_obsindex=1
    fi

fi    

## check dependencies for indices
if [[ $compute_fcindex == 1  && ! $method =~ "none" ]] ; then
    if [[ $nbias == 0 || ( $force == 1 && $stop == "bias" ) || $( comparedate "$biasfiles" "$origfiles" ) == 1 ]] ; then
        compute_debias=1
    fi
fi

if [[ $verbose == 1 ]] ; then
    echo 
     if [[ $compute_debias == 1 && $compute_obsindex == 1 ]] ; then
        echo "Everything has to be recomputed (starting with bias correction)"
    elif [[ $compute_debias == 1 && $compute_obsindex != 1 ]] ; then
        echo "Everything but the observed indices has to be recomputed"
    elif [[ $compute_fcindex == 1 ]] ; then
        if [[ $compute_obsindex == 1 ]] ; then
            echo "Indices have to be recomputed for both the observations and forecasts"
        else
            echo "Indices have to be recomputed only for the forecasts"
        fi
    elif [[ $compute_skill == 1 ]] ; then
        echo "Only skill scores have to be recomputed"
    elif [[ $write_forecasts == 1 ]] ; then
         echo "Forecasts have to be stored as Rdata"
    else
        echo "Nothing to be done -- have a nice day"
    fi
    echo "*************************************************************************"
fi



## standard options for batch processing
STD_OPTIONS="--mail-type=FAIL --mail-user=jonas.bhend@meteoswiss.ch -N 1 --cpus-per-task=1 -p postproc"

jobdepend=""
ojobdepend=""

## spawn off slave jobs

## compute bias correction
if [[ $compute_debias == 1 ]] ; then
    debiascommand="srun Rscript /users/bhendj/R/sbatch_bias_correct.R $model $obs $basevar $grid $bias $init"
    debiasbatch="sbatch --job-name=bias_correct -t 22:00:00 --mem=32GB --parsable \
                        -o bias_correct_${basevar}_${bias}_initmon${init}_%j.log \
                        $STD_OPTIONS /users/bhendj/code/wrapper_jobscript.sbatch $debiascommand"
    if [[ $dry == 1 ]] ; then
        echo $debiasbatch
    else
        jobdepend=$( $debiasbatch )
       
        if [[ $verbose == 1 ]] ; then
            echo "Started bias correction job: $jobdepend"
        fi
    fi
fi

## compute indices on forecasts
if [[ $compute_fcindex == 1 ]] ; then
    ## set offset for dates in ECMWF-System4
    if [[ $model == "ecmwf-system4" ]] ; then
        offset="true"
    else
        offset="false"
    fi
    indexcommand="srun /users/bhendj/code/sbatch_compute_indices.sh $model $index $basevar $grid $method $init $offset"
    if [[ $jobdepend == "" ]] ; then
        dependstring=""
    else
        dependstring=" -d afterok:$jobdepend"
    fi
    indexbatch="sbatch --job-name=indices -t 05:00:00 --mem=18GB --parsable \
                        -o compute_index_${index}_${method}_initmon${init}_%j.log $dependstring \
                        $STD_OPTIONS /users/bhendj/code/wrapper_jobscript.sbatch $indexcommand"

    if [[ $dry == 1 ]] ; then
        echo $indexbatch
    else
        jobdepend=$( $indexbatch)
        
        if [[ $verbose == 1 ]] ; then
            echo "Started index computation job $jobdepend, depends: $dependstring"
        fi
    fi
fi 

## compute indices from observations
if [[ $compute_obsindex == 1 ]] ; then
    oindexcommand="srun /users/bhendj/code/sbatch_compute_obsindices.sh $index $basevar $grid $obs false"
    oindexbatch="sbatch --job-name=obs_indices -t 03:00:00 --mem=18GB --parsable \
                        -o compute_obsindex_${index}_%j.log \
                        $STD_OPTIONS /users/bhendj/code/wrapper_jobscript.sbatch $oindexcommand"

    if [[ $dry == 1 ]] ; then
        echo $oindexbatch
    else
        ojobdepend=$( $oindexbatch )
        
        if [[ $verbose == 1 ]] ; then
            echo "Started index computation with observations job $ojobdepend"
        fi
    fi
fi

## compute skill scores
## if [[ $compute_skill == 1 ]] ; then
    skillcommand="srun Rscript /users/bhendj/R/sbatch_compute_skill.R $model $obs $index $grid $method $init"
    fcstcommand="srun Rscript /users/bhendj/R/sbatch_write_forecasts_to_Rdata.R $model $obs $index $grid $method $init"

    if [[ $jobdepend != "" || $ojobdepend != "" ]] ; then
        if [[ $jobdepend == "" ]] ; then
            dependstring=" -d afterok:$ojobdepend"
        elif [[ $ojobdepend == "" ]] ; then
            dependstring=" -d afterok:$jobdepend"
        else
            dependstring=" -d afterok:${jobdepend}:$ojobdepend"
        fi
    else
        dependstring=""
    fi

    ## for seasonal in TRUE FALSE ; do
    for seasonal in TRUE ; do
        for ccr in FALSE TRUE ; do 
            for detrend in FALSE ; do
                
                if [[ $seasonal == "TRUE" ]] ; then
                    seasstring=seasonal
                else
                    seasstring=monthly
                fi
                
                if [[ $ccr == "TRUE" ]] ; then
                    ccrstring=CCR_
                else

                    ccrstring=""
                fi
                
                if [[ $detrend == "TRUE" ]] ; then
                    detrendstring="detrend_"
                else
                    detrendstring=""
                fi
                
                skillfile=$( \ls $spath/$seasstring/$index/${index}_${detrendstring}${ccrstring}${method}_${model}_vs_${obs}_${years}_initmon$init.nc 2> /dev/null )
                if [[ $force == 1 || ! -f $skillfile || $( comparedate $skillfile $indexfiles ) == 1 || $( comparedate $skillfile $origfiles ) == 1|| $( comparedate $skillfile $obsfiles ) == 1 || $( comparedate $skillfile $obsorig ) == 1 ]] ; then
                    
                    skillbatch="sbatch --job-name=compute_skill -t 05:00:00 --mem=12GB --parsable \
                       -o compute_skill_${index}_initmon${init}_%j.log $dependstring \
                       $STD_OPTIONS /users/bhendj/code/wrapper_jobscript.sbatch $skillcommand $seasonal $ccr $detrend"
                    
                    if [[ $dry == 1 ]] ; then
                        echo $skillbatch
                    else
                        
                        jobid=$( $skillbatch )
                        
                        if [[ $verbose == 1 ]] ; then
                            echo "Started skill scores job $jobid, depends: $dependstring"
                        fi
                    fi  
                fi
            done ## end of for on detrend
        done ## end of for on ccr
    done ## end of for on seasonal
##fi ## end of if on compute_skill


## write forecasts to Rdata files
write_forecasts=0
if [[ $write_forecasts == 1 ]] ; then
    fcstcommand="srun Rscript /users/bhendj/R/sbatch_write_forecasts_to_Rdata.R $index $grid $obs $method $init"

    if [[ $jobdepend != "" || $ojobdepend != "" ]] ; then
        if [[ $jobdepend == "" ]] ; then
            dependstring=" -d afterok:$ojobdepend"
        elif [[ $ojobdepend == "" ]] ; then
            dependstring=" -d afterok:$jobdepend"
        else
            dependstring=" -d afterok:${jobdepend}:$ojobdepend"
        fi
    else
        dependstring=""
    fi

    ## for seasonal in TRUE FALSE ; do
    for seasonal in TRUE ; do
        for ccr in FALSE TRUE ; do 
            for detrend in FALSE ; do
                if [[ $seasonal == "TRUE" ]] ; then
                    seasstring=seasonal
                else
                    seasstring=monthly
                fi
                
                if [[ $ccr == "TRUE" ]] ; then
                    ccrstring=CCR_
                else
                    ccrstring=""
                fi
                
                if [[ $detrend == "TRUE" ]] ; then
                    detrendstring="detrend_"
                else
                    detrendstring=""
                fi

                nfcst=$( \ls $fpath/$seasstring/$index/$method/${index}_${detrendstring}${ccrstring}${grid}_${obs}_${method}_initmon${init}/${index}_${detrendstring}${ccrstring}${grid}_${obs}_${method}_initmon${init}_????_???.Rdata 2> /dev/null | wc -l )
                if [[ ( $force == 1 || $nfcst -lt 20 ) && $seasonal == "TRUE" && $detrend == "FALSE" ]] ; then

                    
                    fcstbatch="sbatch --job-name=write_forecasts -t 03:00:00 --mem=12GB --parsable \
                       -o write_forecasts_${index}_initmon${init}_%j.log $dependstring \
                       $STD_OPTIONS /users/bhendj/code/wrapper_jobscript.sbatch $fcstcommand $seasonal $ccr $detrend"
                    
                    if [[ $dry == 1 ]] ; then
                        echo $fcstbatch
                    else
                        
                        jobid=$( $fcstbatch )
                        
                        if [[ $verbose == 1 ]] ; then
                            echo "Started writing out of forecasts $jobid, depends: $dependstring"
                        fi
                    fi  
                fi
            done ## end of for on detrend
        done ## end of for on ccr
    done ## end of for on seasonal
fi ## end of if on compute_skill


exit
