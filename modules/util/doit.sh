#!/bin/bash

START=/APSshare/epics/synApps_6_2_1/support/areaDetector-R3-12-1

declare -a ADArray=("ADAndor" "ADAravis" "ADEiger" "ADmar345" "ADPilatus" "ADPixirad" "ADPointGrey" "ADProsilica" "ADSimDetector" "ADSpinnaker" "ADURL" "ADVimba")

for val in ${ADArray[@]}; do
cp -r ${START}/${val}/iocs/* .
done

rm ./Makefile

#Eiger and Simdetector are special cases
declare -a ADArray2=("andor" "aravis" "mar345" "pilatus" "pixirad" "pointGrey" "prosilica" "spinnaker" "url" "vimba")

for val in ${ADArray2[@]}; do
   cp ./Makefile1 ./${val}IOC/Makefile
   cp ./CONFIG_SITE ./${val}IOC/configure
   cp ./Makefile2 ./${val}IOC/iocBoot/ioc*/Makefile
done

val=eiger
   cp ./Makefile1 ./${val}IOC/Makefile
   cp ./CONFIG_SITE ./${val}IOC/configure
   cp ./Makefile2 ./${val}IOC/iocBoot/iocEiger1/Makefile
   cp ./Makefile2 ./${val}IOC/iocBoot/iocEiger2/Makefile

val=simDetector   
   cp ./Makefile1 ./${val}IOC/Makefile
   cp ./CONFIG_SITE ./${val}IOC/configure
   cp ./Makefile2 ./${val}IOC/iocBoot/iocHDF5Test/Makefile
   cp ./Makefile2 ./${val}IOC/iocBoot/iocSimDetector/Makefile
