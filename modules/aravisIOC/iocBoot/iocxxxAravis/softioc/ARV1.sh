#!/bin/sh
#
# description: start/stop/restart an EPICS IOC in a screen session
#

# Manually set IOC_STARTUP_DIR if 2iddAV1.sh will reside somewhere other than softioc
#!IOC_STARTUP_DIR=/home/username/epics/ioc/synApps/2iddAV1/iocBoot/ioc2iddAV1/softioc

# Set EPICS_HOST_ARCH if the env var isn't already set properly for this IOC
EPICS_HOST_ARCH=rhel7-x86_64
#EPICS_HOST_ARCH=rhel8-x86_64
#!EPICS_HOST_ARCH=linux-x86_64-debug

IOC_NAME=ARV1
# The name of the IOC binary isn't necessarily the same as the name of the IOC
IOC_BINARY=ADAravisApp

# The RUN_IN variable defines how the IOC should be run. Valid options:
#   screen		(run in a screen session)
#   procServ	(run in procServ)
#   shell		(run on the shell--turns 'start' argument into 'run')
RUN_IN=screen

# The PROCSERV_ENDPOINT variable defines the type of control endpoint to be used
#   tcp			(tcp port)
#   unix		(unix socket)
PROCSERV_ENDPOINT=tcp

# Extra procServ options:
#   -w             start procServ, but require the IOC to be started manually
#   -o             run the IOC once, then quit procServ when the IOC exits
#   --allow        allow telnet access from anywhere
#   --restrict     only allow access from localhost explicitly (the default behavior)
#   -l <endpoint>  create a read-only log endpoint (endpoint = port # or socket filename)
#!PROCSERV_OPTIONS="-w"
#!PROCSERV_OPTIONS="-o"
#!PROCSERV_OPTIONS="--allow"

# The procServ info file is required by this script, but its name can be customized here
PROCSERV_INFO_FILE=ioc${IOC_NAME}-ps-info.txt

# Initial values for procServ endpoints 
PROCSERV_PORT=-1
PROCSERV_SOCKET=ioc${IOC_NAME}.socket

# Change YES to NO in the following line to disable screen-PID lookup, which isn't supported on Windows
GET_SCREEN_PID=YES

# Commands needed by this script
ECHO=echo
ID=id
PGREP=pgrep
SCREEN=screen
KILL=kill
BASENAME=basename
DIRNAME=dirname
READLINK=readlink
PS=ps
#
PROCSERV=procServ
TELNET=telnet
SOCAT=socat
HEAD=head
TAIL=tail
CUT=cut
NC=nc
# Explicitly define paths to commands if commands aren't found
#!ECHO=/bin/echo
#!ID=/usr/bin/id
#!PGREP=/usr/bin/pgrep
#!SCREEN=/usr/bin/screen
#!KILL=/bin/kill
#!BASENAME=/bin/basename
#!DIRNAME=/usr/bin/dirname
#!READLINK=/bin/readlink
#!PS=/bin/ps

#####################################################################

SNAME=${BASH_SOURCE:-$0}
SELECTION=$1
RUN_IN_ARG=$2

# uncomment for your OS here (comment out all the others)
#IOC_STARTUP_FILE="st.cmd.Cygwin"
IOC_STARTUP_FILE="st.cmd.Linux"
#IOC_STARTUP_FILE="st.cmd.vxWorks"
#IOC_STARTUP_FILE="st.cmd.Win32"
#IOC_STARTUP_FILE="st.cmd.Win64"

# Allow the RUN_IN setting to be overridden on the command-line
if [ ! -z ${RUN_IN_ARG} ] ; then
    case ${RUN_IN_ARG} in
        shell)
            RUN_IN=shell
            echo "Overriding RUN_IN with shell"
        ;;

        screen)
            RUN_IN=screen
            echo "Overriding RUN_IN with screen"
        ;;
        
        procServ | ps)
            RUN_IN=procServ
            echo "Overriding RUN_IN with procServ"
        ;;
        
        iocConsole)
            RUN_IN=iocConsole
            echo "Overriding RUN_IN with iocConsole"
        ;;
        
        * )
            # Use the default value of RUN_IN, if RUN_IN_ARG isn't valid
            echo "RUN_IN_ARG isn't valid: ${RUN_IN_ARG}"
        ;;
    esac
fi

if [ -z "$IOC_STARTUP_DIR" ] ; then
    # If no startup dir is specified, use the directory above the script's directory
    IOC_STARTUP_DIR=`dirname ${SNAME}`/..
    IOC_CMD="../../bin/${EPICS_HOST_ARCH}/${IOC_BINARY} ${IOC_STARTUP_FILE}"
else
    IOC_CMD="${IOC_STARTUP_DIR}/../../bin/${EPICS_HOST_ARCH}/${IOC_BINARY} ${IOC_STARTUP_DIR}/${IOC_STARTUP_FILE}"
fi
#!${ECHO} ${IOC_STARTUP_DIR}

# Variables used to calculatate a random port for procServ
START=50000
NUM_PORTS=100

# This variable will be used to perform the correct function for a given argument
RUNNING_IN=TBD

#####################################################################

parse_procServ_info() {
    # This parses procServ info files
    INFO_FILE=$1
    if [ ! -z ${INFO_FILE} ] ; then
        # function was called with an argument
        if [ -f "${INFO_FILE}" ] ; then
            # info file exists
            #!${ECHO} "INFO_FILE = $INFO_FILE"
            
            # Only read the PID from the info file if the PID hasn't been found yet
            if [ -z ${PROCSERV_PID} ] ; then
                # Get PID
                PROCSERV_PID=$(${HEAD} -n 1 ${INFO_FILE} | cut -d ':' -f 2)
                #!${ECHO} ${PROCSERV_PID}
            fi
            
            # Get control endpoint
            CTL_STR=$(${TAIL} -n 1 ${INFO_FILE})
            if [ $(${ECHO} ${CTL_STR} | ${CUT} -d ':' -f 1) == 'tcp' ]; then
                # tcp control endpoint; port is 3rd item
                PROCSERV_PORT=$(${ECHO} ${CTL_STR} | ${CUT} -d ':' -f 3)
                #!${ECHO} ${PROCSERV_PORT}
            else
                # unix control endpoint; socket is 2nd item
                PROCSERV_SOCKET=$(${ECHO} ${CTL_STR} | ${CUT} -d ':' -f 2)
                #!${ECHO} ${PROCSERV_SOCKET}
            fi
        fi
    fi
}

screenpid() {
    if [ ! -z ${SCREEN_PID} ] ; then
        ${ECHO} " in a screen session (pid=${SCREEN_PID})"
    elif [ ! -z ${PROCSERV_PID} ] ; then
        if [ -z ${SAME_HOST} ] ; then
            ${ECHO} " in procServ on a different computer"
        else
            ${ECHO} " in procServ (pid=${PROCSERV_PID})"
        fi
    else
        ${ECHO}
    fi
}

checkpid() {
    MY_UID=`${ID} -u`
    # The '\$' is needed in the pgrep pattern to select 2iddAV1, but not 2iddAV1.sh
    IOC_PID=`${PGREP} ${IOC_BINARY}\$ -u ${MY_UID}`
    #!${ECHO} "IOC_PID=${IOC_PID}"

    if [ "${IOC_PID}" != "" ] ; then
        # Assume the IOC is down until proven otherwise
        IOC_DOWN=1

        # At least one instance of the IOC binary is running; 
        # Find the binary that is associated with this script/IOC
        for pid in ${IOC_PID}; do
            BIN_CWD=`${READLINK} /proc/${pid}/cwd`
            IOC_CWD=`${READLINK} -f ${IOC_STARTUP_DIR}`
            
            if [ "$BIN_CWD" = "$IOC_CWD" ] ; then
                # The IOC is running; the binary with PID=$pid is the IOC that was run from $IOC_STARTUP_DIR
                IOC_PID=${pid}
                IOC_DOWN=0
                
                SCREEN_PID=""
                
                # Assume IOC is running in shell until learning otherwise
                RUNNING_IN=shell
                
                if [ "${GET_SCREEN_PID}" = "YES" ] ; then
                    # Get the PID of the parent of the IOC (shell or screen)
                    P_PID=`${PS} -p ${IOC_PID} -o ppid=`
                    
                    # Get the PID of the grandparent of the IOC (sshd, screen, or ???)
                    GP_PID=`${PS} -p ${P_PID} -o ppid=`

                    #!${ECHO} "P_PID=${P_PID}, GP_PID=${GP_PID}"

                    # Get the screen PIDs
                    S_PIDS=`${PGREP} screen`
                
                    for s_pid in ${S_PIDS} ; do
                        #!${ECHO} ${s_pid}

                        if [ ${s_pid} -eq ${P_PID} ] ; then
                            SCREEN_PID=${s_pid}
				RUNNING_IN=screen

                            break
                        fi
                
                        if [ ${s_pid} -eq ${GP_PID} ] ; then
                            SCREEN_PID=${s_pid}
				RUNNING_IN=screen

                            break
                        fi
                    
                    done
                    
                    # Get the procServ PIDs
                    PS_PIDS=`${PGREP} procServ`
                    
                    for ps_pid in ${PS_PIDS} ; do
                        #!${ECHO} ${ps_pid}
                        
                        if [ ${ps_pid} -eq ${P_PID} ] ; then
                            PROCSERV_PID=${ps_pid}
                            RUNNING_IN=procServ
                            SAME_HOST=True
                            # Read the procServ endpoint info
                            parse_procServ_info ${IOC_STARTUP_DIR}/${PROCSERV_INFO_FILE}
                            break
                        fi
                        
                        if [ ${ps_pid} -eq ${GP_PID} ] ; then
                            PROCSERV_PID=${ps_pid}
                            RUNNING_IN=procServ
                            SAME_HOST=True
                            # Read the procServ endpoint info
                            parse_procServ_info ${IOC_STARTUP_DIR}/${PROCSERV_INFO_FILE}
                            break
                        fi
                    
                    done
                    
                    #!echo "SCREEN_PID=${SCREEN_PID}"
                    #!echo "PROCSERV_PID=${PROCSERV_PID}"
                else
                    # Assume the script is being called from the IOC host
                    SAME_HOST=True
                    parse_procServ_info ${IOC_STARTUP_DIR}/${PROCSERV_INFO_FILE}
                    if [ ! -z ${PROCSERV_PID} ] ; then
                        RUNNING_IN=procServ
                    else
                        RUNNING_IN=screen
                    fi
                fi
                
                break
            
            #else
            #    ${ECHO} "PATHS are different"
            #    ${ECHO} ${BIN_CWD}
            #    ${ECHO} ${IOC_CWD}
            fi
        done
    else
        # The hasn't started yet (procServ's -w option) or it is running on a different computer
        if [ ! -z ${PROCSERV_INFO_FILE} ] ; then
            if [ -f "${IOC_STARTUP_DIR}/${PROCSERV_INFO_FILE}" ] ; then
                # A procServ instance is running for this IOC
                IOC_DOWN=0
                RUNNING_IN=procServ
                IOC_PID=TBD
                
                # Get the procServ PID
                parse_procServ_info ${IOC_STARTUP_DIR}/${PROCSERV_INFO_FILE}
                
                # Get the procServ PIDs
                PS_PIDS=`${PGREP} procServ`
                
                # Get the instances of procServ on this computer
                for ps_pid in ${PS_PIDS}
                do
                    #!${ECHO} ${ps_pid}
                    if [ ${ps_pid} -eq ${PROCSERV_PID} ] ; then
                        # This script is running on the computer with the procServ instance that will eventually run the IOC
                        SAME_HOST=True
                        break
                    fi
                done
            else
                # procServ isn't running
                IOC_DOWN=1
            fi
        else
            # IOC is not running
            IOC_DOWN=1
        fi
    fi

    return ${IOC_DOWN}
}

start() {
    if checkpid; then
        ${ECHO} -n "${IOC_NAME} is already running (pid=${IOC_PID})"
        screenpid
    else
        ${ECHO} "Starting ${IOC_NAME}"
        cd ${IOC_STARTUP_DIR}
        
        case ${RUN_IN} in
            shell)
                # Run 2iddAV1 outside of a screen session, which is helpful for debugging
                ${IOC_CMD}
            ;;
            
            screen)
                # Run 2iddAV1 inside a screen session
                ${SCREEN} -dm -S ${IOC_NAME} -h 5000 ${IOC_CMD}
            ;;
            
            procServ)
                # Run 2iddAV1 inside procServ
                if [ ${PROCSERV_ENDPOINT} == 'tcp' ]; then
                    # Pick a random port, unless the script is configured to use a specific one
                    if [ ${PROCSERV_PORT} == '-1' -o -z ${PROCSERV_PORT} ]; then
                        PROCSERV_PORT=$(get_random_port)
                    fi
                    
                    # Start procServ with a tcp control endpoint
                    ${PROCSERV} ${PROCSERV_OPTIONS} -i ^C --logoutcmd=^D -I ${PROCSERV_INFO_FILE} ${PROCSERV_PORT} ${IOC_CMD}
                elif [ ${PROCSERV_ENDPOINT} == 'unix' ]; then
                    # Pick a socket name, if it is commented out above
                    if [ ! -z ${PROCSERV_SOCKET} ]; then
                        PROCSERV_SOCKET=ioc${IOC_NAME}.socket
                    fi
                    
                    # Start procServ with a unix socket control endpoint
                    ${PROCSERV} ${PROCSERV_OPTIONS} -i ^C --logoutcmd=^D -I ${PROCSERV_INFO_FILE} unix:${PROCSERV_SOCKET} ${IOC_CMD}
                else
                    ${ECHO} "Can't start ${IOC_NAME} in procServ: PROCSERV_ENDPOINT has an invalid value: ${PROCSERV_ENDPOINT}"
                fi
            ;;
            
            * )
                echo "Error: invalid value for RUN_IN: ${RUN_IN}"
            ;;
        esac
    fi
}

stop() {
    if checkpid; then
        case ${RUNNING_IN} in
            procServ)
                if [ ! -z ${SAME_HOST} ]; then
                    ${ECHO} "Stopping ${IOC_NAME} (procServ pid=${PROCSERV_PID})"
                    ${KILL} ${PROCSERV_PID}
                else
                    ${ECHO} "Can't kill the IOC. It is running in procServ on a different computer."
                fi
            ;;
            
            * )
                ${ECHO} "Stopping ${IOC_NAME} (pid=${IOC_PID})"
                ${KILL} ${IOC_PID}
            ;;
        esac
    else
        ${ECHO} "${IOC_NAME} is not running"
    fi
}

restart() {
    stop
    start
}

status() {
    if checkpid; then
        ${ECHO} -n "${IOC_NAME} is running (pid=${IOC_PID})"
        screenpid
    else
        ${ECHO} "${IOC_NAME} is not running"
    fi
}

console() {
    if checkpid; then
        case ${RUNNING_IN} in
            procServ)
                if [ ! -z ${SAME_HOST} ]; then
                    # It is assumed that the port or socket have been read successfully from the info file
                    if [ ${PROCSERV_ENDPOINT} == 'tcp' ]; then
                        ${ECHO} "Connecting to ${IOC_NAME}'s procServ with ${TELNET}"
                        ${TELNET} 127.0.0.1 ${PROCSERV_PORT}
                    elif [ ${PROCSERV_ENDPOINT} == 'unix' ]; then
                        ${ECHO} "Connecting to ${IOC_NAME}'s procServ with ${SOCAT}"
                        cd ${IOC_STARTUP_DIR}
                        ${SOCAT} -,rawer,echo=0 unix-connect:${PROCSERV_SOCKET}
                    else
                        ${ECHO} "Error: no procServ port or socket specified"
                    fi
                else
                    # This could be smarter in the future
                    ${ECHO} "Can't connect to the console; procServ is running on another computer"
                fi
            ;;
            
            screen)
                ${ECHO} "Connecting to ${IOC_NAME}'s screen session"
                # The -r flag will only connect if no one is attached to the session
                #!${SCREEN} -r ${IOC_NAME}
                # The -x flag will connect even if someone is attached to the session
                ${SCREEN} -x ${IOC_NAME}
            ;;
            
            * )
                ${ECHO} "Can't connect to ${IOC_NAME}; it isn't running in screen or procServ"
            ;;
        esac
    else
        ${ECHO} "${IOC_NAME} is not running"
    fi
}

run() {
    if checkpid; then
        ${ECHO} -n "${IOC_NAME} is already running (pid=${IOC_PID})"
        screenpid
    else
        ${ECHO} "Starting ${IOC_NAME}"
        cd ${IOC_STARTUP_DIR}
        # Run 2iddAV1 outside of a screen session, which is helpful for debugging
        ${IOC_CMD}
    fi
}

start_medm() {
#    ${IOC_STARTUP_DIR}/../../start_MEDM_2iddAV1
     ${IOC_STARTUP_DIR}/start_medm
}

start_caqtdm() {
#    ${IOC_STARTUP_DIR}/../../start_caQtDM_2iddAV1
     ${IOC_STARTUP_DIR}/start_caqtdm
}

usage() {
    ${ECHO} "Usage: $(${BASENAME} ${SNAME}) {start|stop|restart|status|console|run|medm|caqtdm}"
    ${ECHO}
    ${ECHO} "Additional options:"
    ${ECHO} "       $(${BASENAME} ${SNAME}) start {screen|procServ|ps|shell}"
}

get_random_port() {
    # Get a random port for procServ
    while :
    do
        i=$(( $RANDOM % $NUM_PORTS + $START ))
        ${NC} -z localhost $i
        if [ $? ]
        then
            echo "$i"
            break
        fi
    done
}

#####################################################################

if [ ! -d ${IOC_STARTUP_DIR} ] ; then
    ${ECHO} "Error: ${IOC_STARTUP_DIR} doesn't exist."
    ${ECHO} "IOC_STARTUP_DIR in ${SNAME} needs to be corrected."
else
     ALIVE=/APSshare/bin/alivedb
     if test -f "$ALIVE"; then
     OUTPUT=$($ALIVE ioc${IOC_NAME} -s)
     echo $OUTPUT
     fi

    case ${SELECTION} in
        start)
#            if [[ $OUTPUT == *"Up"* ]]; then
#            exit 1
#            else
            start
#            fi
        ;;

        stop | kill)
            stop
        ;;

        restart)
            restart
        ;;

        status)
            status
        ;;

        console)
            console
        ;;

        run)
            run
        ;;
        
        medm)
            start_medm
        ;;
        
        caqtdm)
            start_caqtdm
        ;;

        *)
            usage
        ;;
    esac
fi
