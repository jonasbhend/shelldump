#!/bin/bash

# this script helps to facilitate processing of all GCM and RCM
# runs for the east Africa case (LEAP)

cd $HOME/logs

for method in fastqqmap ; do
  for model in ecmwf-system4 SMHI-EC-EARTH SMHI-RCA4 UCAN-WRF341G UL-IDL-WRF360D DWD-CCLM4-8-21 ; do
      for varname in tasmin tasmax pr ; do
          master_skill_scores.sh -v $model WFDEI $varname EAF-22 $method 05
      done
  done
done

exit