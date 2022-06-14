
doit() 
{
export EPICS_HOST_ARCH=$1; make clean;
mkdir -p ./bin/$1/libs; 
make;
ldd ./bin/$1/xxx | grep "=> /APS" | awk '{print $3}' | xargs -I '{}' cp -v '{}' ./bin/$1/libs
chmod -R 755 ./bin/$1/libs 
}

do7()
{

doit linux-x86_64;
doit linux-x86_64-debug;
doit linux-x86_64-static;

doit rhel7-x86_64
doit rhel7-x86_64-debug
doit rhel7-x86_64-static

}

do8()
{

doit rhel8-x86_64
doit rhel8-x86_64-debug
doit rhel8-x86_64-static

}

full=`cat /etc/redhat-release | tr -dc '0-9.'`
major=$(cat /etc/redhat-release | tr -dc '0-9.'|cut -d \. -f1)
minor=$(cat /etc/redhat-release | tr -dc '0-9.'|cut -d \. -f2)

if [ $major == 7 ]
then

do7

fi

if [ $major == 8 ]
then

do8

fi




