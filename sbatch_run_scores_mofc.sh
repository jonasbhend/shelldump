#!/usr/local/bin/bash

grid=eobs0.44
dpath=/store/msclim/bhendj/MOFC/$grid

## enquire current directory
curdir=`pwd`
TMPDIR=$SCRATCH/sbatch_files
mkdir -p $TMPDIR


## loop through variable name and debiasing options
for granul in weekly ; do
    for varname in tas  ; do
        for method in none unbias-crossval1 ; do
            files=$(\ls $dpath/$granul/$varname/${method}*/*.nc )
            for file in $files ; do
                
                outdir=$( dirname $file | sed "s/MOFC/MOFC_scores/g" )
                outfile=scores_$( basename $file )
                
                if [[ ! -f $outdir/$outfile ]] ; then
                    batchfile=$TMPDIR/scores_${varname}_${method}_${RANDOM}.batch
                    echo $varname $method $file $batchfile
                    
                ## write the batch file
                    cat > $batchfile <<EOF
#!/usr/local/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=mofc_scores
#SBATCH --mail-type=FAIL
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8GB
#SBATCH --partition=postproc
#SBATCH --output=$HOME/logs/mofc_scores_${varname}_${method}_%j.log

#======START=====
srun Rscript /users/bhendj/R/sbatch_compute_skill_mofc.R $file

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
