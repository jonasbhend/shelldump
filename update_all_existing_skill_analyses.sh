#!/bin/bash

## update all existing skill scores
skillpath=/store/msclim/bhendj/EUPORIAS/skill_scores
cd $skillpath
grids=$( \ls -d * )
## for grid in $grids ; do
for grid in eobs0.44 global2 ; do
    cd $skillpath/$grid/seasonal
    varnames=$( \ls -d *)
    for varname in $varnames ; do
    ## for varname in pr ; do
        cd $skillpath/$grid/seasonal/$varname
        sfiles=$( \ls *.nc )
        for file in $sfiles ; do
            method=$( echo $file | sed -e "s/${varname}_//g" -e "s/_19.*//g" )
            if [[ $method =~ "none" ]] ; then
                method=$( echo $method | sed "s/_.*//g" )
            fi
            init=$( echo $file | sed -e "s/.*initmon//g" -e "s/.nc//g" )
            model=$( echo $file | sed -e "s/_vs.*//g" -e "s/.*_//g" )
            obs=$( echo $file | sed -e "s/.*_vs_//g" -e "s/_.*//g" )
            if [[ ! ( $method =~ "CCR" || $method =~ "detrend" ) ]] ; then
                cd $HOME/logs
                master_skill_scores.sh -v  $model $obs $varname $grid $method $init
            fi

        done
    done
done

exit

# targets=$( \ls -d /store/msclim/bhendj/EUPORIAS/*/*/daily/*/* )

# for target in $targets ; do
#     if [[ ! -f $target ]] ; then
#         model=$( echo $target | sed -e 's_.*EUPORIAS/__g' -e 's_/_ _g' | awk '{ print $1 }' )
#         grid=$( echo $target | sed -e 's_.*EUPORIAS/__g' -e 's_/_ _g' | awk '{ print $2 }' )
#         varname=$( echo $target | sed -e 's_.*EUPORIAS/__g' -e 's_/_ _g' | awk '{ print $4 }' )
#         method=$( echo $target | sed -e 's_.*EUPORIAS/__g' -e 's_/_ _g' | awk '{ print $5 }' | sed 's/_.*//g' )
#         obs=$( echo $target | sed -e 's_.*EUPORIAS/__g' -e 's_/_ _g' | awk '{ print $5 }' | sed 's/.*_//g' )
#         files=$( \ls $target/*.nc )
#         if [[ $files != "" && ! $method =~ "none" ]] ; then
#             inits=""
#             for f in $files ; do
#                 fi=$( basename $f )
#                 init=$( echo $fi | cut -c 5-6 )
#                 if [[ ! $inits =~ $init ]] ; then
#                     inits="$inits $init"
#                 fi
#             done

#             for init in $inits ; do
#                 echo $model $obs $varname $grid $method $init
#                 master_skill_scores.sh -v $model $obs $varname $grid $method $init
#             done
#         fi
#     fi
# done