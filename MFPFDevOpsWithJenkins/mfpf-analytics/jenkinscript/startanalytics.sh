#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

#!/usr/bin/bash

usage()
{
   echo
   echo " Running the MobileFirst Operational Analytics Image as a Container "
   echo " -----------------------------------------------------------------------------"
   echo " This script runs the MobileFirst Operational Analytics image as a container"
   echo " on the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareanalytics.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments): "
   echo "   USAGE: startanalytics.sh <command-line arguments>"
   echo "   command-line arguments: "
   echo "   -a | --api BLUEMIX_API_URL       (Optional) Bluemix API endpoint. Defaults to https://api.ng.bluemix.net"
   echo "   -r | --registry BLUEMIX_REGISTRY (Optional) IBM Containers Registry Host"
   echo "                                      Defaults to registry.ng.bluemix.net"
   echo "   -h | --host BLUEMIX_CCS_HOST     (Optional) IBM Containers Cloud Service Host"
   echo "                                      Defaults to https://containers-api.ng.bluemix.net/v3/containers"
   echo "   -u | --user BLUEMIX_USER         Bluemix user ID or email address (If not provided, assumes ICE is already logged-in.)"
   echo "   -p | --password BLUEMIX_PASSWORD Bluemix password"
   echo "   -o | --org BLUEMIX_ORG           Bluemix organization"
   echo "   -s | --space BLUEMIX_SPACE       Bluemix space"
   echo "     -t | --tag  ANALYTICS_IMAGE_TAG       Tag for the analytics image"
   echo "     -n | --name ANALYTICS_CONTAINER_NAME  Name of the analytics container"
   echo "     -i | --ip   ANALYTICS_IP              IP address the analytics container should be bound to"
   echo "     -hp | --http EXPOSE_HTTP               (Optional) Expose HTTP Port. Accepted values are Y (default) or N"
   echo "     -hs | --https EXPOSE_HTTPS             (Optional) Expose HTTPS Port. Accepted values are Y (default) or N"
   echo "     -m | --memory SERVER_MEM              (Optional) Assign a memory limit to the container in megabytes (MB)"
   echo "                                             Accepted values are 1024 (default), 2048,..."
   echo "     -se | --ssh SSH_ENABLE                (Optional) Enable SSH for the container. Accepted values are Y (default) or N"
   echo "     -sk | --sshkey SSH_KEY                (Optional) SSH Key to be injected into the container"
   echo "     -tr | --trace TRACE_SPEC              (Optional) Trace specification to be applied to MobileFirst Server"
   echo "     -ml | --maxlog MAX_LOG_FILES          (Optional) Maximum number of log files to maintain before overwriting"
   echo "     -ms | --maxlogsize MAX_LOG_FILE_SIZE  (Optional) Maximum size of a log file"
   echo "     -v | --volume ENABLE_VOLUME           (Optional) Enable mounting volume for container logs. Accepted values are Y or N (default)"
   echo "     -ev | --enabledatavolume ENABLE_ANALYTICS_DATA_VOLUME       (Optional) Enable mounting volume for analytics data. Accepted values are Y or N (default)"
   echo "     -av | --datavolumename ANALYTICS_DATA_VOLUME_NAME           (Optional) Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_NAME>"
   echo "     -ad | --analyticsdatadirectory ANALYTICS_DATA_DIRECTORY     (Optional) Specify the directory to be used for storing analytics data. Default value is /analyticsData"
   echo "     -e | --env MFPF_PROPERTIES            (Optional) Provide related MobileFirst Operational Analytics image properties as comma-separated"
   echo "                                             key:value pairs. Example: serviceContext:analytics-service"
   echo
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: startanalytics.sh <path to the file from which arguments are read>"
   echo "          See args/startanalytics.properties for the list of arguments."
   echo
   echo " Interactive Execution: "
   echo "   USAGE: startanalytics.sh"
   echo
   exit 1
}

readParams()
{

   # Read the tag for the MobileFirst Operational Analytics image 
   #-------------------------------------------------------------
   INPUT_MSG="Specify the tag for the analytics image. Should be of form registryUrl/repositoryNamespace/tag (mandatory) : "
   ERROR_MSG="Tag for analytics image cannot be empty. Specify the tag for the analytics image. Should be of form registryUrl/repositoryNamespace/tag (mandatory) : "
   ANALYTICS_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the name of the MobileFirst Operational Analytics container  
   #-----------------------------------------------------------------
   INPUT_MSG="Specify the name for the analytics container (mandatory) : "
   ERROR_MSG="Analytics Container name cannot be empty. Specify the name for the analytics container (mandatory) : "
   ANALYTICS_CONTAINER_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the IP for the MobileFirst Operational Analytics container 
   #----------------------------------------------------------------
   INPUT_MSG="Specify the IP address for the analytics container (mandatory) : "
   ERROR_MSG="Incorrect IP Address. Specify a valid IP address for the analytics container (mandatory) : "
   ANALYTICS_IP=$(fnReadIP "$INPUT_MSG" "$ERROR_MSG")

   # Expose HTTP/HTTPS Port 
   #-----------------------
   INPUT_MSG="Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : "
   ERROR_MSG="Input should be either Y or N. Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTP=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   INPUT_MSG="Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : "
   ERROR_MSG="Input should be either Y or N. Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTPS=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   # Read the memory for the server container 
   #-----------------------------------------
   INPUT_MSG="Specify the memory size limit (in MB) for the server container. Accepted values are 1024, 2048,.... The default value is 1024 MB. (optional) : "
   ERROR_MSG="Error due to non-numeric input. Specify a valid number (in MB) for the memory size limit. Valid values are 1024, 2048,... The default value is 1024 MB (optional) : "
   SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")

   # Read the SSH details  
   #---------------------
   INPUT_MSG="Enable SSH For the server container. Accepted values are Y or N. The default value is Y. (optional) : " 
   ERROR_MSG="Input should be either Y or N. Enable SSH For the server container. Accepted values are Y or N. The default value is Y. (optional) : "
   SSH_ENABLE=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   # Read the SSH details
   #---------------------
   if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
   then
      read -p "Provide an SSH Key to be injected into the container. Provide the contents of your id_rsa.pub file (optional): " SSH_KEY
   fi

   # Read the Mounting Volume for server Data
   #------------------------------------------
   INPUT_MSG="Enable mounting volume for the server container logs. Accepted values are Y or N. The default value is N. (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for the server container logs. Accepted values are Y or N. The default value is N. (optional) : " 
   ENABLE_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

   # Read the Mounting Volume for Analytics Data details  
   #----------------------------------------------------
   INPUT_MSG="Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N. (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N. (optional) : "
   ENABLE_ANALYTICS_DATA_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

   if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
   then   
       read -p "Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_NAME> (optional) : " ANALYTICS_DATA_VOLUME_NAME
   fi
   
   read -p "Specify the directory to be used for storing analytics data. The default value is /analyticsData (optional) : " ANALYTICS_DATA_DIRECTORY

   # Read the Trace details  
   #-----------------------  
   read -p "Provide the Trace specification to be applied to the MobileFirst Server. The default value is *=info (optional): " TRACE_SPEC

   # Read the maximum number of log files 
   #-------------------------------------
   INPUT_MSG="Provide the maximum number of log files to maintain before overwriting them. The default value is 5 files. (optional): "
   ERROR_MSG="Error due to non-numeric input. Provide the maximum number of log files to maintain before overwriting them. The default value is 5 files. (optional): "
   MAX_LOG_FILES=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "5")

   # Maximum size of a log file in MB 
   #----------------------------------
   INPUT_MSG="Maximum size of a log file (in MB). The default value is 20 MB. (optional): "
   ERROR_MSG="Error due to non-numeric input. Specify a number to represent the maximum log file size (in MB) allowed. The default value is 20 MB. (optional): "
   MAX_LOG_FILE_SIZE=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "20")

   # Specify the MFP related properties  
   #-----------------------------------   
   read -p "Specify related MobileFirst Operational Analytics properties as comma-separated key:value pairs (optional) : "

}

validateParams()
{
               if [ -z "$BLUEMIX_API_URL" ]
                then
                    BLUEMIX_API_URL=https://api.ng.bluemix.net
                fi

                if [ "$(validateURL $BLUEMIX_API_URL)" = "1" ]
                then
                    echo IBM Bluemix API URL is incorrect. Exiting...
                    exit 0
                fi

                if [ -z "$BLUEMIX_REGISTRY" ]
                then
                    BLUEMIX_REGISTRY=registry.ng.bluemix.net
                fi

                if [ -z "$BLUEMIX_CCS_HOST" ]
                then
                    BLUEMIX_CCS_HOST=https://containers-api.ng.bluemix.net/v3
                fi

                if [ "$(validateURL $BLUEMIX_CCS_HOST)" = "1" ]
                then
                    echo IBM Containers Cloud service host URL is incorrect. Exiting...
                    exit 0
                fi

                if [ -z "$BLUEMIX_USER" ]
                then
                    echo IBM Bluemix Email ID/UserID field is empty. A mandatory argument must be specified. Exiting...
                    exit 0
                fi

                if [ -z "$BLUEMIX_PASSWORD" ]
                then
                    echo IBM Bluemix Password field is empty. A mandatory argument must be specified. Exiting...
                    exit 0
                fi
                if [ -z "$BLUEMIX_ORG" ]
                then
                    echo IBM Bluemix Organization field is empty. A mandatory argument must be specified. Exiting...
                    exit 0
                fi
                if [ -z "$BLUEMIX_SPACE" ]
                then
                    echo IBM Bluemix Space field is empty. A mandatory argument must be specified. Exiting...
                    exit 0
                fi


	if [ -z "$ANALYTICS_IMAGE_TAG" ]
	then
    		echo Analytics Image Tag is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi
	
	if [ -z "$ANALYTICS_CONTAINER_NAME" ]
	then
    		echo Analytics Container Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi

	if [ -z "$ANALYTICS_IP" ]
	then
    		echo Analytics Container IP Address field is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi
	
	if [ "$(valid_ip $ANALYTICS_IP)" = "1" ]
	then
		    echo Analytics Container IP Address is incorrect. Exiting...
	        exit 0
	fi

   if [ -z "$SERVER_MEM" ]
   then
      SERVER_MEM=1024
   fi

	if [ "$(isNumber $SERVER_MEM)" = "1" ]
    then
        echo  Required Analytics Container Memory must be a Number. Exiting...
	    exit 0
    fi

   if [ -z "$SSH_ENABLE" ]
   then
     SSH_ENABLE=Y
   fi

	if [ "$(validateBoolean $SSH_ENABLE)" = "1" ]
    then
        echo  Invalid Value for SSH_ENABLE. Values must be either Y / N. Exiting...
	    exit 0
    fi

   if [ -z "$ENABLE_VOLUME" ]
   then 
      ENABLE_VOLUME=N
   fi

	if [ "$(validateBoolean $ENABLE_VOLUME)" = "1" ]
    then
        echo  Invalid Value for ENABLE_VOLUME. Values must be either Y / N. Exiting...
	    exit 0
    fi

   if [ -z "$ENABLE_ANALYTICS_DATA_VOLUME" ]
   then
      ENABLE_ANALYTICS_DATA_VOLUME=N
   fi   

	if [ "$(validateBoolean $ENABLE_ANALYTICS_DATA_VOLUME)" = "1" ]
    then
        echo  Invalid Value for ENABLE_ANALYTICS_DATA_VOLUME. Values must be either Y / N. Exiting...
	    exit 0
    fi
   
   if [ -z "$ANALYTICS_DATA_VOLUME_NAME" ]
   then
      ANALYTICS_DATA_VOLUME_NAME=mfpf_analytics_$ANALYTICS_CONTAINER_NAME
   fi   
    
   if [ -z "$ANALYTICS_DATA_DIRECTORY" ]
   then
      ANALYTICS_DATA_DIRECTORY=/analyticsData
   fi  
   
   if [ -z "$EXPOSE_HTTP" ]
   then
      EXPOSE_HTTP=Y
   fi

	if [ "$(validateBoolean $EXPOSE_HTTP)" = "1" ]
    then
        echo  Invalid Value for EXPOSE_HTTP. Values must be either Y / N. Exiting...
	    exit 0
    fi

   if [ -z "$EXPOSE_HTTPS" ]
   then
      EXPOSE_HTTPS=Y
   fi

	if [ "$(validateBoolean $EXPOSE_HTTPS)" = "1" ]
    then
        echo  Invalid Value for EXPOSE_HTTPS. Values must either Y / N. Exiting...
	    exit 0
    fi
}

createDataVolume()
{
   volume_exists="False"
   volumes="$(ice volume list)"
   if [ ! -z "${volumes}" ]
   then
      for oneVolume in ${volumes}
      do
         if [[ "${oneVolume}" = "${ANALYTICS_DATA_VOLUME_NAME}" ]]
         then
            volume_exists="True"
            break
         fi
      done
   fi
   if [[ "${volume_exists}" = "True" ]]
   then
      echo "Volume already exists: $ANALYTICS_DATA_VOLUME_NAME. This volume will be used to store analytics data."
   else
      echo "The volume $ANALYTICS_DATA_VOLUME_NAME will be created to store analytics data."
      eval "ice volume create $ANALYTICS_DATA_VOLUME_NAME"
   fi
}

createVolumes() 
{
  echo "Creating volumes"
  
  sysvol_exist="False"
  libertyvol_exist="False"
  
  volumes="$(ice volume list)"

  if [ ! -z "${volumes}" ]
   then
      for mVar in ${volumes}
      do
         if [[ "$mVar" = "$SYSVOL_NAME" ]]
         then
            sysvol_exist="True"
            continue
         elif [[ "$mVar" = "$LIBERTYVOL_NAME" ]]
         then
           libertyvol_exist="True"
         fi
      done
   fi

   if [[ "$sysvol_exist" = "True" ]]
   then
      echo "Volume already exists: $SYSVOL_NAME. This volume will be used to store sys logs."
   else
      echo "The volume $SYSVOL_NAME will be created to store sys logs."
      eval "ice volume create $SYSVOL_NAME"
   fi
   
   if [[ "$libertyvol_exist" = "True" ]]
   then
      echo "Volume already exists: $LIBERTYVOL_NAME. This volume will be used to store Liberty logs."
   else
      echo "The volume $LIBERTYVOL_NAME will be created to store Liberty logs."
      eval "ice volume create $LIBERTYVOL_NAME"
   fi
}

#INIT
# The volume name and the path in the container that the volume will be mounted
SYSVOL_NAME=sysvol
LIBERTYVOL_NAME=libertyvol
SYSVOL_PATH=/var/log/rsyslog
LIBERTYVOL_PATH=/opt/ibm/wlp/usr/servers/worklight/logs

source ../../jenkins-common-scripts/common.sh
source ../usr/env/server.env

cd "$( dirname "$0" )"

if [ $# == 0 ]
then
   readParams
elif [ "$#" -eq 1 -a -f "$1" ]
then
   source "$1"
elif [ "$1" = "-h" -o "$1" = "--help" ]
then
   usage
else
   while [ $# -gt 0 ]; do
      case "$1" in
         -a | --api)
            BLUEMIX_API_URL="$2";
            shift
            ;;
         -r | --registry)
            BLUEMIX_REGISTRY="$2";
            shift
            ;;
         -h | --host)
            BLUEMIX_CCS_HOST="$2";
            shift
            ;;
         -u | --user)
            BLUEMIX_USER="$2";
            shift
            ;;
         -p | --password)
            BLUEMIX_PASSWORD="$2";
            shift
            ;;
         -o | --org)
            BLUEMIX_ORG="$2";
            shift
            ;;
         -s | --space)
            BLUEMIX_SPACE="$2";
            shift
            ;;
         -t | --tag)
            ANALYTICS_IMAGE_TAG="$2";
            shift
            ;;
         -n | --name)
            ANALYTICS_CONTAINER_NAME="$2";
            shift
            ;;
         -i | --ip)
            ANALYTICS_IP="$2";
            shift
            ;;
         -se | --ssh)
            SSH_ENABLE="$2";
            shift
            ;;
       	 -v | --volume)
            ENABLE_VOLUME="$2";
            shift
            ;;
         -ev | --enabledatavolume)
            ENABLE_ANALYTICS_DATA_VOLUME="$2";
            shift
            ;;   
         -av | --datavolumename)
            ANALYTICS_DATA_VOLUME_NAME="$2";
            shift
            ;; 
         -ad | --analyticsdatadirectory)
            ANALYTICS_DATA_DIRECTORY="$2";
            shift
            ;;  
         -hp | --http)
            EXPOSE_HTTP="$2";
            shift
            ;;
         -hs | --https)
            EXPOSE_HTTPS="$2";
            shift
            ;;
         -m | --memory)
            SERVER_MEM="$2";
            shift
            ;;
         -e | --env)
            MFPF_PROPERTIES="$2";
            shift
            ;;
         -sk | --sshkey)
            SSH_KEY="$2";
            shift
            ;;
         -tr | --trace)
            TRACE_SPEC="$2";
            shift
            ;;
         -ml | --maxlog)
            MAX_LOG_FILES="$2";
            shift
            ;;
         -ms | --maxlogsize)
            MAX_LOG_FILE_SIZE="$2";
            shift
            ;;
         *)
            usage
            ;;
      esac
      shift
   done
fi

validateParams
source ../../jenkins-common-scripts/ice_common_commands.sh
source ../../jenkins-common-scripts/initenv.sh -u $BLUEMIX_USER -p $BLUEMIX_PASSWORD -o $BLUEMIX_ORG -s $BLUEMIX_SPACE

#main

set -e

echo "Arguments : "
echo "----------- "
echo
echo "BLUEMIX_API_URL : " $BLUEMIX_API_URL
echo "BLUEMIX_REGISTRY : " $BLUEMIX_REGISTRY
echo "BLUEMIX_CCS_HOST : " $BLUEMIX_CCS_HOST
echo "BLUEMIX_USER : " $BLUEMIX_USER
echo "BLUEMIX_PASSWORD : " XXXXXXXX
echo "BLUEMIX_ORG : " $BLUEMIX_ORG
echo "BLUEMIX_SPACE : " $BLUEMIX_SPACE
echo "ANALYTICS_IMAGE_TAG : " $ANALYTICS_IMAGE_TAG
echo "ANALYTICS_CONTAINER_NAME : " $ANALYTICS_CONTAINER_NAME
echo "ANALYTICS_IP : " $ANALYTICS_IP
echo "SSH_ENABLE : " $SSH_ENABLE
echo "ENABLE_VOLUME : " $ENABLE_VOLUME
echo "ENABLE_ANALYTICS_DATA_VOLUME : " $ENABLE_ANALYTICS_DATA_VOLUME
echo "ANALYTICS_DATA_VOLUME_NAME : " $ANALYTICS_DATA_VOLUME_NAME
echo "ANALYTICS_DATA_DIRECTORY : " $ANALYTICS_DATA_DIRECTORY
echo "EXPOSE_HTTP : " $EXPOSE_HTTP
echo "EXPOSE_HTTPS : " $EXPOSE_HTTPS
echo "SERVER_MEM : " $SERVER_MEM
echo "SSH_KEY : " $SSH_KEY
echo "TRACE_SPEC : " $TRACE_SPEC
echo "MAX_LOG_FILES : " $MAX_LOG_FILES
echo "MAX_LOG_FILE_SIZE : " $MAX_LOG_FILE_SIZE
echo "MFPF_PROPERTIES : " $MFPF_PROPERTIES
echo

args[0]="createContainer"
args[1]=$BLUEMIX_CCS_HOST
args[2]=$access_token
args[3]=$spaceGUID
args[4]=$ANALYTICS_IMAGE_TAG
args[5]=$ANALYTICS_CONTAINER_NAME 
args[6]=$SERVER_MEM

if [ -z "$TRACE_SPEC" ]
then
TRACE_SPEC="*~info"
fi

if [ -z "$MAX_LOG_FILES" ]
then
MAX_LOG_FILES="5"
fi

if [ -z "$MAX_LOG_FILE_SIZE" ]
then
MAX_LOG_FILE_SIZE="20"
fi

environmentProps="TRACE_LEVEL=$TRACE_SPEC, MAX_LOG_FILES=$MAX_LOG_FILES, MAX_LOG_FILE_SIZE=$MAX_LOG_FILE_SIZE"

if [ ! -z "$MFPF_PROPERTIES" ]
then
        environmentProps="$environmentProps,mfpfproperties=$MFPF_PROPERTIES"
fi

if [ "$ENABLE_VOLUME" = "Y" ] || [ "$ENABLE_VOLUME" = "y" ]
then
   createVolumes
   volumes="$SYSVOL_NAME:$SYSVOL_PATH, $LIBERTYVOL_NAME:$LIBERTYVOL_PATH"
   environmentProps="$environmentProps, LOG_LOCATIONS=$SYSVOL_PATH/syslog,$LIBERTYVOL_PATH/messages.log,$LIBERTYVOL_PATH/console.log,$LIBERTYVOL_PATH/trace.log"
fi

if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
then
   createDataVolume
   volumes="$volumes, $ANALYTICS_DATA_VOLUME_NAME:$ANALYTICS_DATA_DIRECTORY"
   environmentProps="$environmentProps, ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY"
else
        environmentProps="$environmentProps, ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY"
fi

args[7]="$environmentProps"
args[8]="null"
if [ ! -z "$SSH_KEY" ] && ([ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ])
then
        KeyName=$ANALYTICS_DATA_VOLUME_NAME
else
        KeyName="null"
fi
args[9]="$KeyName"



ports="9500"
if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
then
   ports="$ports ,22"
fi


if [ "$EXPOSE_HTTP" = "Y" ] || [ "$EXPOSE_HTTP" = "y" ]
then
        ports="$ports , $ANALYTICS_HTTPPORT"
fi
if [ "$EXPOSE_HTTPS" = "Y" ] || [ "$EXPOSE_HTTPS" = "y" ]
then
   ports="$ports , $ANALYTICS_HTTPSPORT"
fi
args[10]="$ports"
args[11]="null"
args[12]="null"
args[13]="$volumes"
args[14]=0
args[15]="null"

createCtrResponse=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "createContainer" ${args[1]} ${args[2]} ${args[3]} ${args[4]} ${args[5]} ${args[6]} "$environmentProps" ${args[8]} ${args[9]} "$ports" ${args[11]} ${args[12]} "$volumes" ${args[14]} ${args[15]})
#echo "Create container response is $createCtrResponse"
if  [[ $createCtrResponse == Error* ]]  ; then
        echo "Error Occured in creation of container - Quitting!"
        exit 1
fi
echo "Create Server Successful"

ctrId=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer 'getCtrIdWithName' "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $ANALYTICS_CONTAINER_NAME)

checkContainerStatusWithWait "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $ANALYTICS_CONTAINER_NAME "ipAction"

ipAssignResponse=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "assignIP" "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $ctrId $ANALYTICS_IP )
#echo "Ip assign is $ipAssignResponse"
if  [[ $ipAssignResponse == Error* ]]  ; then
        echo "Error Occured in ip assignment to container - Quitting!"
        exit 1
fi

echo "End of Create Analytics Server"
