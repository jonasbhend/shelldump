#!/bin/bash

## Please note that this script is not safe
## if run with multiple indices (e.g. HDD and tas)
## and multiple observations (e.g. ERA-INT and E-OBS)
## as bias correction and computation of indices
## will be performed unneccessarily often

cd $HOME/logs

optstring=$@

## grids="eobs0.44 global2"
grids="global2"
for grid in $grids ; do 
    if [[ $grid == "eobs0.44" ]] ; then
        observations="E-OBS ERA-INT"
    else
        observations="ERA-INT"
    fi
    for obs in $observations ; do
        ## for index in NDD02 NDD10 PDD98 PDD90 ; do
        for index in tas ITV NDD02 NDD10 PDD98 PDD90 HDDch CDD ; do
        
        ## for index in tas ; do
        ## for index in pr ; do
            ## biases="none smooth-forward smooth_scale-forward trend-forward conditional-forward smoothccr-forward"
            ## biases="smooth-crossval1 smooth_scale-crossval1 trend-crossval1 conditional-crossval1"
            biases="none smooth-forward trend-forward conditional-forward comb-forward smoothRecal-forward trendRecal-forward conditionalRecal-forward combRecal-forward fastqqmap-forward"
            ## biases="none-forward smooth_mul-forward"
            ## biases="none smooth smooth_scale trend conditional smoothccr"
            case $index in
                tas ) 
                    initmonths="05 11"
                    ;;
                pr|dtr ) 
                    initmonths="05 11" 
                    biases="none-forward smooth_mul"
                    ;; 
                tasmax|CDD|PDD* ) initmonths=05 ;;
                tasmin|HDD|HDDch|FD|NDD* ) initmonths=11 ;;
                ITV ) initmonths="05 11" ;;
            esac
            
            if [[ $index == "tas" || $index == "PDD98" ]] ; then
                biases="$biases smooth-crossval1 smooth-crossval10 comb-crossval1 comb-crossval10 comb smooth fastqqmap fastqqmap-crossval1 fastqqmap-crossval10"
            fi

            for bias in $biases ; do
                for initmon in $initmonths ; do
                    master_skill_scores.sh $optstring $index $grid $obs $bias $initmon
                    
                done
            done
        done
    done
done

exit
