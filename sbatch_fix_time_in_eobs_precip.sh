#!/bin/bash

cd $HOME/logs

dpath=/store/msclim/bhendj/EUPORIAS/ecmwf-system4/eobs0.44/daily/Precip

year=1980
while [[ $year -lt 2013 ]] ; do
    let year=year+1

    batchfile=$HOME/logs/$year.batchfile
    
    ## write the batch file
    cat > $batchfile <<EOF
#!/bin/bash

#SBATCH --mail-user=jonas.bhend@meteoswiss.ch
#SBATCH --job-name=bias_correct
#SBATCH --mail-type=FAIL
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8GB
#SBATCH --partition=postproc
#SBATCH --output=$HOME/logs/$year.fix_%j.log

cd $dpath
for f in ${year}*.nc ; do 
  echo \$f 
  of=\$( \ls /store/msclim/sysclim/ecmwf/system4/daily/deg075/Precip/\${f/0.44/} )
  echo \$of 
  out=\$(basename \$of) 
  ncrename -h -O -v time,time2 \$f \$SCRATCH/\$f 
  ncks -h -A -v time \$of \$SCRATCH/\$f 
  ncks -h -O -x -v time2 \$SCRATCH/\$f \$f 
  rm $SCRATCH/$f
done

exit

EOF

    sbatch $batchfile
    rm $batchfile

done

exit