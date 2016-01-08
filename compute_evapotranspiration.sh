#!/bin/bash

## very simple script to read in two netcdf files
## compute an index and write out another netcdf file
## might serve as a template for more sophisticated
## (e.g. including more variables) computations


infile1=$1
infile2=$2
outfile=$3

TMPDIR=$SCRATCH/evapotranspiration_$$

if [[ $verbos == 1 ]] ; then
    echo $infile1 
    echo $infile2 
    echo $outfile 
    echo $TMPDIR
fi

## change to temporary directory
pdir=$( pwd )
mkdir $TMPDIR
cd $TMPDIR

## generate R script for computation
cat > $TMPDIR/ept.R <<EOF
library(myhelpers)

args <- commandArgs(TRUE)
infiles <- args[1:2]
outfile <- args[3]

input <- lapply(infiles, function(x){
  nc <- nc_open(x)
  on.exit(nc_close(nc))
  ncvars <- names(nc[['var']])
  tasname <- ncvars[grep("tasmax|tasmin|mn2t24|mx2t24", ncvars)]
  if (length(tasname) > 1) stop()
  out <- ncvar_get(nc, tasname)
  attr(out, "time") <- nc_time(nc)
  attr(out, 'lat') <- nc[['dim']][['lat']][['vals']]
  attr(out, 'varname') <- tasname
  return(out)
})

## chek dimensions align
stopifnot(dim(input[[1]]) == dim(input[[2]]))
## check time aligns
stopifnot(attr(input[[1]], 'time') == attr(input[[2]], 'time'))


## check which is max and min temperature
in.mn <- sapply(input, mean, na.rm=T)
names(input) <- c("tasmin", "tasmax")[order(in.mn)]

## compute evapotranspiration
hargreavesDay.arr <- function(tmin, tmax){
  nlon <- nrow(tmin)
  nlat <- ncol(tmin)
  nens <- if (length(dim(tmin)) == 3) 1 else dim(tmin)[3]
  ntime <- dim(tmin)[length(dim(tmin))]
  Tavg <- (tmin + tmax)/2
  if (any(Tavg > 200)) Tavg <- Tavg - 273.15
  Tr <- pmax(tmax - tmin, 0)
  J <- as.POSIXlt(attr(tmin, 'time'))[['yday']] + 1
  delta<-0.409*sin(0.0172*J-1.39) 
  dr<-1+0.033*cos(0.0172*J) 
  latr <- attr(tmin, 'lat') / 57.2957795
  sset <- outer(tan(latr), tan(delta), '*')
  omegas <- sset*0
  omegas[abs(sset) <= 1] <- acos(sset[abs(sset) <= 1])
  omegas[sset < -1] <- max(omegas)
  ## Ra has dimension lat x time
  Ra <- pmax(37.6*rep(dr, each=length(latr))*(omegas * outer(sin(latr), sin(delta), '*') + sin(omegas)*outer(cos(latr), cos(delta), '*')), 0)
  ## change dimension of Ra for final output
  Ra <- as.vector(Ra[rep(1:nlat, each=nlon), rep(1:ntime, each=nens)])
  ept <- pmax(0.0023*0.408*Ra*(Tavg + 17.78) * sqrt(Tr), 0)
  return(ept)
}

ept <- hargreavesDay.arr(input[['tasmin']], input[['tasmax']])

## write to output file
outvar <- attr(input[[1]], 'varname')
nc_write(nctempfile=infiles[1], file=outfile, 
         varname=outvar, data=ept, append=FALSE)

## fix attributes and variable names
system(paste0('ncrename -h -v ', outvar, ',ept ', outfile))
system(paste0("ncatted -h -a standard_name,ept,o,c,potential_evapotranspiration ", outfile))
system(paste0("ncatted -h -a units,ept,o,c,'mm d-1' ", outfile))
system(paste0("ncatted -h -a long_name,ept,o,c,'reference potential evapotranspiration after Hargreaves and Samani (1985)' ", outfile))

q(save= 'no')

EOF


## get basename of outfile for local processing
outf=$(basename $outfile)

## run R script
## echo "Rscript ept.R $infile1 $infile2 $outf"
Rscript ept.R $infile1 $infile2 $outf

if [[ -f $outf ]] ; then
  mkdir -p "$( dirname $outfile )"
  mv $outf $outfile
  rm -rf $TMPDIR
fi

cd $pdir

exit