#!/bin/bash

## this is a simple script to benchmark easyVerification
## trying to prevent the zombie process problem from taking over

j=0
while [[ $j -lt 36 ]] ; do
let j=j+1
echo $j

cat > Rtmp.R <<EOF
library(easyVerification)
library(rbenchmark)
library(parallel)

if (file.exists('~/tmp/benchmark_easyverification.Rdata')){
  load('~/tmp/benchmark_easyverification.Rdata')
} else {
  tm <- toyarray(1)
  btmp <- benchmark(tmroc <- veriApply("EnsRocss", tm[['fcst']], tm[['obs']], parallel=TRUE, ncpu=1, prob=1:4/5), replications=10)
  bench <- expand.grid(ncpu=2^(0:5), size=10^(0:5))
  bench <- cbind(bench, array(NA, c(nrow(bench), length(btmp))))
  names(bench)[-(1:2)] <- names(btmp)  
}

## loop through configs
i <- min(which(is.na(bench[['elapsed']])))
print(paste("Size: ", bench[i,'size']))
print(paste("nCPU: ", bench[i,'ncpu']))
tm <- toyarray(bench[i,'size'])
bench[i,-(1:2)] <- benchmark(tmroc <- veriApply("EnsRocss", tm[['fcst']], tm[['obs']], parallel=TRUE, ncpu=bench[i,'ncpu'], prob=1:4/5), replications=10)
save(bench, file="~/tmp/benchmark_easyverification.Rdata")
q(save='no')

EOF

R CMD BATCH Rtmp.R
rm Rtmp.R

done

exit
