#!/usr/local/bin/bash

grid=eobs0.44
dpath=/store/msclim/bhendj/MOFC/$grid

## enquire current directory
curdir=`pwd`
TMPDIR=$SCRATCH/sbatch_files
mkdir -p $TMPDIR


## loop through variable name and debiasing options
for  granul in weekly ; do
    for varname in tas  ; do
        files=$(\ls $dpath/$granul/$varname/none/*.nc )
        for method in unbias-crossval1 ; do
            for file in $files ; do

                outfile=$( echo $file | sed -e "s/none/${method}_E-OBS/g" -e "s/.nc/_${method}_E-OBS.nc/g" )

                if [[ ! -f $outfile ]] ; then
                    batchfile=$TMPDIR/${varname}_${method}_${RANDOM}.batch
                    echo $varname $method $file $batchfile
                    
            ## write the batch file
                    cat > $batchfile <<EOF
#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=mofc_bias
#SBATCH --mail-type=FAIL
#SBATCH --time=04:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=18GB
#SBATCH --partition=postproc
#SBATCH --output=$HOME/logs/mofc_bias_${varname}_${method}_%j.log

#======START=====
srun Rscript /users/bhendj/R/sbatch_bias_correct_mofc.R $file $method

EOF
                
                    sbatch $batchfile
                    rm $batchfile
                fi
            done
        done
    done
done

rm -rf $TMPDIR

exit

# 
# sbatch_run_bias_correction_mofc.sh ends here
