#!/usr/bin/bash

nevents=${1}
outbase=${2}
logbase=${3}
runnumber=${4}
segment=${5}
outdir=${6}
build=${7/./}
dbtag=${8}
inputs=(`echo ${9} | tr "," " "`)  # array of input files 
ranges=(`echo ${10} | tr "," " "`)  # array of input files with ranges appended
logdir=${11:-.}
histdir=${12:-.}
subdir=${13}
payload=(`echo ${14} | tr ","  " "`) # array of files to be rsynced

{

export USER="$(id -u -n)"
export LOGNAME=${USER}
export HOME=/sphenix/u/${USER}
hostname

source /opt/sphenix/core/bin/sphenix_setup.sh -n ${7}

export ODBCINI=./odbc.ini

echo ..............................................................................................
echo $@
echo .............................................................................................. 
echo nevents: $nevents
echo outbase: $outbase
echo logbase: $logbase
echo runnumb: $runnumber
echo segment: $segment
echo outdir:  $outdir
echo build:   $build
echo dbtag:   $dbtag
echo inputs:  ${inputs[@]}
echo subdir:  ${subdir}
echo payload: ${payload[@]}

echo .............................................................................................. 

for i in ${payload[@]}; do
    cp --verbose ${subdir}/${i} .
done

#______________________________________________________________________________________ started __
#
./cups.py -r ${runnumber} -s ${segment} -d ${outbase} started
#_________________________________________________________________________________________________


if [[ "${9}" == *"dbinput"* ]]; then
  for i in $(./cups.py -r ${runnumber} -s ${segment} -d ${outbase} getinputs); do
     cp -v ${i} .
     echo $( basename $i ) >> inlist   
  done
else
  for i in ${inputs[@]}; do
     cp -v ${i} .
     echo $( basename $i ) >> inlist   
  done
fi

cat inlist

./cups.py -r ${runnumber} -s ${segment} -d ${outbase} running

dstname=${logbase%%-*}

echo root.exe -q -b Fun4All_TrkrHitSet_Unpacker.C\(${nevents},${runnumber},\"${logbase}.root\",\"${dbtag}\",\"inlist\"\)
     root.exe -q -b Fun4All_TrkrHitSet_Unpacker.C\(${nevents},${runnumber},\"${logbase}.root\",\"${dbtag}\",\"inlist\"\);  status_f4a=$?

ls -la

echo ./stageout.sh ${logbase}.root ${outdir}
     ./stageout.sh ${logbase}.root ${outdir}

for hfile in `ls HIST_*.root`; do
    echo Stageout ${hfile} to ${histdir}
    ./stageout.sh ${hfile} ${histdir}
done

ls -la

# Flag run as finished. 
echo ./cups.py -v -r ${runnumber} -s ${segment} -d ${outbase} finished -e ${status_f4a} --nevents ${nevents}  
     ./cups.py -v -r ${runnumber} -s ${segment} -d ${outbase} finished -e ${status_f4a} --nevents ${nevents}

echo "bdee bdee bdee, That's All Folks!"

} >${logdir#file:/}/${logbase}.out  2>${logdir#file:/}/${logbase}.err


exit $status_f4a