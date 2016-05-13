#~/bin/bash

for model in SMHI-EC-EARTH SMHI-RCA4 DWD-CCLM4-8-21 UCAN-WRF341G UL-IDL-WRF360D ; do
    for varname in wb ept ; do
        for granul in monthly daily ; do
            for method in none fastqqmap_1991-2012_WFDEI ; do
                cd /store/msclim/bhendj/EUPORIAS/$model/EAF-22/$granul/$varname/$method
                for f in *.nc ; do
                    fout=$(echo $f | sed -e "s/^${varname}_//g" -e "s/_${varname}_/_${varname}_${granul}_${model}_/" )
                    echo $f
                    echo $fout
                    ln $f /store/msclim/bhendj/EUPORIAS/tmp/data_for_upload_to_SMHI/$varname/$granul/$fout
                done
            done
        done
    done
done

exit
