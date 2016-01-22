#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Running the MobileFirst Operational Analytics Image as a Container Group "
   echo " ---------------------------------------------------------------------------------- "
   echo " Use this script to run the MobileFirst Operational Analytics"
   echo " image as a container group on the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareanalytics.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments): "
   echo "   USAGE: startanalyticsgroup.sh <command line arguments> "
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
   echo "     -t | --tag ANALYTICS_IMAGE_TAG                    The tag to be used for tagging the analytics image"
   echo "     -gn | --name ANALYTICS_CONTAINER_GROUP_NAME       The name of the analytics container group"
   echo "     -gh | --host ANALYTICS_CONTAINER_GROUP_HOST       The host name of the route"
   echo "     -gs | --domain ANALYTICS_CONTAINER_GROUP_DOMAIN   The domain name of the route"
   echo "     -gm | --min ANALYTICS_CONTAINER_GROUP_MIN         (Optional) The minimum number of instances. The default value is 1"
   echo "     -gx | --max ANALYTICS_CONTAINER_GROUP_MAX         (Optional) The maximum number of instances. The default value is 2"
   echo "     -gd | --desired ANALYTICS_CONTAINER_GROUP_DESIRED (Optional) The desired number of instances. The default value is 2"
   echo "     -bi | --backup ANALYTICS_MASTER_BACKUP_IP         The public ip address of the analytics master backup node"
   echo "     -mi | --master ANALYTICS_MASTER_IP                The public ip address of the analytics master node"
   echo "     -tr | --trace TRACE_SPEC             (Optional) Trace specification to be applied to MobileFirst Server"
   echo "     -ml | --maxlog MAX_LOG_FILES         (Optional) Maximum number of log files to maintain before overwriting"
   echo "     -ms | --maxlogsize MAX_LOG_FILE_SIZE (Optional) Maximum size of a log file"
   echo "     -e | --env MFPF_PROPERTIES           (Optional) MFP Analytics related properties as comma separated key:value pairs"
   echo "     -em | --envm MFPF_PROPERTIES_MASTER  (Optional) MFP Analytics related properties as comma separated key:value pairs"
   echo "     -m | --memory SERVER_MEM             (Optional) Assign a memory limit to the container in MB. Accepted values"
   echo "                                            are 1024 (default), 2048,..."
   echo " -v | --volume ENABLE_VOLUME              (Optional) Enable mounting volume for the container logs. Accepted values are Y (default) or N"
   echo "     -ev | --enabledatavolume ENABLE_ANALYTICS_DATA_VOLUME       (Optional) Enable mounting volume for analytics data. Accepted values are Y or N (default)"
   echo "     -av | --datavolumename ANALYTICS_DATA_VOLUME_NAME           (Optional) Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_GROUP_NAME>"
   echo "     -ad | --analyticsdatadirectory ANALYTICS_DATA_DIRECTORY     (Optional) Specify the directory to be used for storing analytics data. Default value is /analyticsData"
   echo "     -se | --ssh SSH_ENABLE                (Optional) Enable SSH for master containers"
   echo "                                             Accepted values are Y or N(default)"
   echo "     -sk | --sshkey SSH_KEY               (Optional) SSH Key to be injected into the master containers"
   echo 
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: startanalyticsgroup.sh <path to the file from which arguments are read>"
   echo "          See args/startanalyticsgroup.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: startanalyticsgroup.sh"
   echo
   exit 1
}

readParams()
{

	# Read the tag for the MobileFirst Operational Analytics image
	#-------------------------------------------------------------
	INPUT_MSG="Specify the tag for the analytics image. Should be of form registryUrl/repositoryNamespace/tag (mandatory) : "
	ERROR_MSG="Tag for server image cannot be empty. Specify the tag for the analytics image. Should be of form registryUrl/repositoryNamespace/tag (mandatory) : " 
	ANALYTICS_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

	# Read the name of the MobileFirst Operational Analytics container group
	#-----------------------------------------------------------------------
	INPUT_MSG="Specify the name for the analytics container group (mandatory) : "
	ERROR_MSG="Container group name cannot be empty. Specify the name for the analytics container group (mandatory) : "
	ANALYTICS_CONTAINER_GROUP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
	
	# Read the minimum number of instances
	#-------------------------------------
	INPUT_MSG="Specify the minimum number of instances. The default value is 1 (optional) : "
	ERROR_MSG="Error due to non-numeric input. Specify the minimum number of instances. The default value is 1 (optional) : "
	ANALYTICS_CONTAINER_GROUP_MIN=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1")
	
	# Read the maximum number of instances
	#-------------------------------------
	INPUT_MSG="Specify the maximum number of instances. The default value is 2 (optional) : " 
	ERROR_MSG="Error due to non-numeric input. Specify the maximum number of instances. The default value is 2 (optional) : " 
	ANALYTICS_CONTAINER_GROUP_MAX=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "2")
	
	# Read the desired number of instances
	#-------------------------------------
	INPUT_MSG="Specify the desired number of instances. The default value is 2 (optional) : "
	ERROR_MSG="Error due to non-numeric input. Specify the desired number of instances. The default value is 2 (optional) : "
	ANALYTICS_CONTAINER_GROUP_DESIRED=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "2")            

	# Read the host name of the route
	#--------------------------------
	INPUT_MSG="Specify the host name of the route (special characters are not allowed) (mandatory) : "
	ERROR_MSG="Host name cannot be empty. Specify the host name of the route (special characters are not allowed) (mandatory) : "
	ANALYTICS_CONTAINER_GROUP_HOST=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
	
	# Read the domain of the route
	#-----------------------------
	INPUT_MSG="Specify the domain of the route (mandatory) : "
	ERROR_MSG="Domain cannot be empty. Specify the domain of the route (mandatory) : "
	ANALYTICS_CONTAINER_GROUP_DOMAIN=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
   
   # Read the IP for the master node 
   #---------------------------------
   INPUT_MSG="Specify the IP address of the master node (mandatory) : "
   ERROR_MSG="Incorrect IP address. Specify the correct IP address of the master node (mandatory) : "
   ANALYTICS_MASTER_IP=$(fnReadIP "$INPUT_MSG" "$ERROR_MSG")
   
   # Read the IP for the master backup node 
   #---------------------------------
   INPUT_MSG="Specify the IP address of the master backup node (mandatory) : "
   ERROR_MSG="Incorrect ip address. Specify the correct IP address of the master backup node (mandatory) : "
   ANALYTICS_MASTER_BACKUP_IP=$(fnReadIP "$INPUT_MSG" "$ERROR_MSG")

   # Read the memory for the server container
   #-----------------------------------------
   INPUT_MSG="Specify the memory size limit (in MB) for the server container. Accepted values are 1024, 2048,... The default value is 1024 MB (optional) : "
   ERROR_MSG="Error due to non-numeric input. Specify a valid value. Valid values are 1024, 2048,... The default value is 1024 MB. (optional) : "
   SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")
 
   # Read the mount volume/ssh/trace details 
   #----------------------------------------
   
   INPUT_MSG="Enable mounting volume for the server container logs. Accepted values are Y or N. The default value is N (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for the server container logs. Accepted values are Y or N. The default value is N (optional) : "
   ENABLE_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")
  
   # Read the analytics data volume details 
   #----------------------------------------
   
   INPUT_MSG="Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for analytics data. Accepted values are Y or N. The default value is N (optional) : "
   ENABLE_ANALYTICS_DATA_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")

   if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
   then   
       read -p "Specify name of the volume to be created and mounted for analytics data. Default value is mfpf_analytics_<ANALYTICS_CONTAINER_GROUP_NAME> (optional) : " ANALYTICS_DATA_VOLUME_NAME
   fi
   read -p "Specify the directory to be used for storing analytics data. Default value is /analyticsData (optional) : " ANALYTICS_DATA_DIRECTORY
   
   # Read the ssh details 
   #---------------------
   
   INPUT_MSG="Enable SSH For the server container. Accepted values are Y or N. The default value is Y (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable SSH For the server container. Accepted values are Y or N. The default value is Y (optional) : "
   SSH_ENABLE=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
   then
      read -p "Provide an SSH Key to be injected into the master containers. Provide the contents of your id_rsa.pub file (optional): " SSH_KEY
   fi

   read -p "Provide the Trace specification to be applied to the MobileFirst Server. The default value is *=info (optional): " TRACE_SPEC
  
   # Read the maximum number of log files
   #-------------------------------------
   INPUT_MSG="Provide the maximum number of log files to maintain before overwriting them. The default value is 5 (optional): "
   ERROR_MSG="Error due to non-numeric input. Provide the maximum number of log files to maintain before overwriting them. The default value is 5 (optional): " 
   MAX_LOG_FILES=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "5")

   # Maximum size of a log file in MB
   #----------------------------------
   INPUT_MSG="Maximum size of a log file in MB. The default value is 20 (optional): "
   ERROR_MSG="Error due to non-numeric input. Specify the maximum size of a log file in MB. The default value is 20 (optional): " 
   MAX_LOG_FILE_SIZE=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "20")

   # Specify the related MobileFirst Platform Foundation properties 
   #---------------------------------------------------------------   
	read -p "Specify the MobileFirst Operational Analytics related properties as comma separated key:value pairs (optional) : " MFPF_PROPERTIES
	read -p "Specify the MobileFirst Operational Analytics related properties for the master nodes as comma separated key:value pairs (optional) : " MFPF_PROPERTIES_MASTER

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
	
	if [ -z "$ANALYTICS_CONTAINER_GROUP_NAME" ]
	then
    		echo Analytics Container Group Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi
	
	if [ -z "$ANALYTICS_CONTAINER_GROUP_HOST" ]
	then
    		echo Analytics Container Group Host is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi
	
	if [ `expr "$ANALYTICS_CONTAINER_GROUP_HOST" : ".*[!@#\$%^\&*()_+].*"` -gt 0 ]
    then 
       	echo Analytics Container Group Host name should not contain special characters. Exiting...
		exit 0 
    fi

	if [ -z "$ANALYTICS_CONTAINER_GROUP_DOMAIN" ]
	then
    		echo Analytics Container Group Domain is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi

	if [ -z "$ANALYTICS_HTTPPORT" ]
	then
    		echo ANALYTICS_HTTPPORT is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi
	
	if [ -z "$ANALYTICS_HTTPSPORT" ]
	then
    		echo ANALYTICS_HTTPSPORT is empty. A mandatory argument must be specified. Exiting...
			exit 0
	fi

	#if [ -z "$ANALYTICS_MASTER_IP" ]
	#then
    	#	echo Analytics Container Master IP Address field is empty. A mandatory argument must be specified. Exiting...
	#		exit 0
	#fi
	
	#if [ "$(valid_ip $ANALYTICS_MASTER_IP)" = "1" ]
	#then
	#	    echo Analytics Container Master IP Address is incorrect. Exiting...
	#        exit 0
	#fi
	
	#if [ -z "$ANALYTICS_MASTER_BACKUP_IP" ]
	#then
    	#	echo Analytics Container Master Backup IP Address field is empty. A mandatory argument must be specified. Exiting...
	#		exit 0
	#fi
	
	#if [ "$(valid_ip $ANALYTICS_MASTER_BACKUP_IP)" = "1" ]
	#then
	#	    echo Analytics Container Master Backup IP Address is incorrect. Exiting...
	#        exit 0
	#fi

   	if [ -z $ANALYTICS_CONTAINER_GROUP_MIN ]
   	then 
     		ANALYTICS_CONTAINER_GROUP_MIN=1;
   	fi

	if [ "$(isNumber $ANALYTICS_CONTAINER_GROUP_MIN)" = "1" ]
    	then
        	echo  Required Analytics Container Group Min No. of Instances must be a Number. Exiting...
	        exit 0
    	fi

   	if [ -z $ANALYTICS_CONTAINER_GROUP_MAX ]
   	then 
      		ANALYTICS_CONTAINER_GROUP_MAX=2;
   	fi

	if [ "$(isNumber $ANALYTICS_CONTAINER_GROUP_MAX)" = "1" ]
    then
        echo  Required Analytics Container Group Max No. of Instances must be a Number. Exiting...
	        exit 0
    fi

   if [ -z $ANALYTICS_CONTAINER_GROUP_DESIRED ]
   then 
      ANALYTICS_CONTAINER_GROUP_DESIRED=2;
   fi
	
	if [ "$(isNumber $ANALYTICS_CONTAINER_GROUP_DESIRED)" = "1" ]
    then
        echo  Required Analytics Container Group Desired No. of Instances must be a Number. Exiting...
	    exit 0
    fi

   if [ -z "$SERVER_MEM" ]
   then 
      SERVER_MEM=1024
   fi
	
	if [ "$(isNumber $SERVER_MEM)" = "1" ]
    then
        echo  Required Analytics Container Group Memory must be a Number. Exiting...
	    exit 0
    fi


   if [ -z "$SSH_ENABLE" ]
   then
      SSH_ENABLE=Y
   fi

	if [ "$(validateBoolean $SSH_ENABLE)" = "1" ]
    then
        echo  Invalid Value for ENABLE_VOLUME. Values must be either Y / N. Exiting...
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
        echo  Invalid Value for ENABLE_VOLUME. Values must be either Y / N. Exiting...
	    exit 0
    fi
   
   if [ -z "$ANALYTICS_DATA_VOLUME_NAME" ]
   then
      ANALYTICS_DATA_VOLUME_NAME=mfpf_analytics_$ANALYTICS_CONTAINER_GROUP_NAME
   fi   
    
   if [ -z "$ANALYTICS_DATA_DIRECTORY" ]
   then
      ANALYTICS_DATA_DIRECTORY=/analyticsData
   fi  

   
   if [ -z "$ANALYTICS_MASTER_NAME" ]
   then
      ANALYTICS_MASTER_NAME=$ANALYTICS_CONTAINER_GROUP_NAME"master"
   fi
   
   if [ -z "$ANALYTICS_MASTER_BACKUP_NAME" ]
   then
      ANALYTICS_MASTER_BACKUP_NAME=$ANALYTICS_CONTAINER_GROUP_NAME"master_backup"
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

#INIT
# The volume name and the path in the container that the volume will be mounted
SYSVOL_NAME=sysvol
LIBERTYVOL_NAME=libertyvol
SYSVOL_PATH=/var/log/rsyslog
LIBERTYVOL_PATH=/opt/ibm/wlp/usr/servers/worklight/logs

cd "$( dirname "$0" )"

source ../../jenkins-common-scripts/common.sh
source ../usr/env/server.env
source ../../jenkins-common-scripts/ice_common_commands.sh

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
         -gn | --name)
            ANALYTICS_CONTAINER_GROUP_NAME="$2";
            shift
            ;;
         -gm | --min)
            ANALYTICS_CONTAINER_GROUP_MIN="$2";
            shift
            ;;
         -gx | --max)
            ANALYTICS_CONTAINER_GROUP_MAX="$2";
            shift
            ;;
         -gd | --desired)
            ANALYTICS_CONTAINER_GROUP_DESIRED="$2";
            shift
            ;;
         -gh | --host)
            ANALYTICS_CONTAINER_GROUP_HOST="$2";
            shift
            ;;
         -gs | --domain)
            ANALYTICS_CONTAINER_GROUP_DOMAIN="$2";
            shift
            ;;
         -m | --memory)
            SERVER_MEM="$2";
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
         -e | --env)
            MFPF_PROPERTIES="$2";
            shift
            ;;
         -em | --envm)
            MFPF_PROPERTIES_MASTER="$2";
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
         -sk | --sshkey)
            SSH_KEY="$2";
            shift
            ;;
         -mi | --master)
            ANALYTICS_MASTER_IP="$2";
            shift
            ;;
         -bi | --backup)
            ANALYTICS_MASTER_BACKUP_IP="$2";
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
echo "ANALYTICS_CONTAINER_GROUP_NAME : " $ANALYTICS_CONTAINER_GROUP_NAME
echo "ANALYTICS_CONTAINER_GROUP_MIN : " $ANALYTICS_CONTAINER_GROUP_MIN
echo "ANALYTICS_CONTAINER_GROUP_MAX : " $ANALYTICS_CONTAINER_GROUP_MAX
echo "ANALYTICS_CONTAINER_GROUP_DESIRED : " $ANALYTICS_CONTAINER_GROUP_DESIRED
echo "ANALYTICS_CONTAINER_GROUP_HOST : " $ANALYTICS_CONTAINER_GROUP_HOST
echo "ANALYTICS_CONTAINER_GROUP_DOMAIN : " $ANALYTICS_CONTAINER_GROUP_DOMAIN
echo "ANALYTICS_MASTER_NAME : " $ANALYTICS_MASTER_NAME
echo "ANALYTICS_MASTER_BACKUP_NAME : " $ANALYTICS_MASTER_BACKUP_NAME
echo "ANALYTICS_MASTER_BACKUP_IP : " $ANALYTICS_MASTER_BACKUP_IP
echo "ANALYTICS_MASTER_IP : " $ANALYTICS_MASTER_IP
echo "SERVER_MEM : " $SERVER_MEM
echo "TRACE_SPEC : " $TRACE_SPEC
echo "MAX_LOG_FILES : " $MAX_LOG_FILES
echo "MAX_LOG_FILE_SIZE : " $MAX_LOG_FILE_SIZE
echo "MFPF_PROPERTIES : " $MFPF_PROPERTIES
echo "MFPF_PROPERTIES_MASTER : " $MFPF_PROPERTIES_MASTER
echo "ENABLE_VOLUME : " $ENABLE_VOLUME
echo "ENABLE_ANALYTICS_DATA_VOLUME : " $ENABLE_ANALYTICS_DATA_VOLUME
echo "ANALYTICS_DATA_VOLUME_NAME : " $ANALYTICS_DATA_VOLUME_NAME
echo "ANALYTICS_DATA_DIRECTORY : " $ANALYTICS_DATA_DIRECTORY
echo "SSH_ENABLE : " $SSH_ENABLE
echo "SSH_KEY : " $SSH_KEY

ANALYTICS_COMM_PORT=9600
ANALYTICS_DEBUG_PORT=9500

echo "This assumes the group doesn't exist already.  Please make sure to add the removeContainerGroup step if required."


echo "Creating a new container group"

#=====================================Preparing the array for the container group creation ======================================
#args 1 - bluemix url
#args 2 - accesstoken
#args 3 - space guid
#args 4 - ANALYTICS_IMAGE_TAG
#args 5 - ANALYTICS_CONTAINER_GROUP_NAME
#args 6 - SERVER_MEM
#args 7 - ANALYTICS_CONTAINER_GROUP_MIN
#args 8 - ANALYTICS_CONTAINER_GROUP_MAX
#args 9 - ANALYTICS_CONTAINER_GROUP_DESIRED
#args 10 - volumes
#args 11 - ports
#args 12 - app Name
#args 13 - environment properties
#args 14 - command - which is null for mfp
#args 15 - ANALYTICS_CONTAINER_GROUP_HOST
#args 16 - ANALYTICS_CONTAINER_GROUP_DOMAIN

args[0]="createContainerGrp"
args[1]=$BLUEMIX_CCS_HOST
args[2]=$access_token
args[3]=$spaceGUID
args[4]=$ANALYTICS_IMAGE_TAG
args[5]=$ANALYTICS_CONTAINER_GROUP_NAME
args[6]=$SERVER_MEM
args[7]=$ANALYTICS_CONTAINER_GROUP_MIN
args[8]=$ANALYTICS_CONTAINER_GROUP_MAX
args[9]=$ANALYTICS_CONTAINER_GROUP_DESIRED

environmentProps=null
volumes=null
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

TRACE_SPEC=${TRACE_SPEC//"="/"~"}
environmentProps="ANALYTICS_TRACE_LEVEL=$TRACE_SPEC, ANALYTICS_MAX_LOG_FILES=$MAX_LOG_FILES, ANALYTICS_MAX_LOG_FILE_SIZE=$MAX_LOG_FILE_SIZE,ANALYTICS_multicast=true"

if [ ! -z "$MFPF_PROPERTIES" ]
then
        environmentProps="${environmentProps}, mfpfproperties==$MFPF_PROPERTIES"
fi

if [ "$ENABLE_VOLUME" = "Y" ] || [ "$ENABLE_VOLUME" = "y" ]
then
   createVolumes
   volumes="$SYSVOL_NAME:$SYSVOL_PATH, $LIBERTYVOL_NAME:$LIBERTYVOL_PATH"
   environmentProps="${environmentProps}, LOG_LOCATIONS=$SYSVOL_PATH/syslog,$LIBERTYVOL_PATH/messages.log,$LIBERTYVOL_PATH/console.log,$LIBERTYVOL_PATH/trace.log"
fi
if [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "Y" ] || [ "$ENABLE_ANALYTICS_DATA_VOLUME" = "y" ]
then
   createDataVolume
   if [ -z "$volumes" ]; then
            echo "volumes is empty"
                volumes="$ANALYTICS_DATA_VOLUME_NAME:$ANALYTICS_DATA_DIRECTORY"
        else
                volumes="${volumes}, $ANALYTICS_DATA_VOLUME_NAME:$ANALYTICS_DATA_DIRECTORY"
        fi
   environmentProps="${environmentProps}, ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY"
else
   environmentProps="${environmentProps}, ANALYTICS_DATA_DIRECTORY=$ANALYTICS_DATA_DIRECTORY"
fi


if [ -n "$ANALYTICS_MASTER_BACKUP_IP" ]
then
        echo "in master back up ip "
        environmentProps="${environmentProps}, ANALYTICS_masternodes=$ANALYTICS_MASTER_IP:$ANALYTICS_COMM_PORT,$ANALYTICS_MASTER_BACKUP_IP:$ANALYTICS_COMM_PORT"
        echo "in master back up ip in if ${environmentProps} "
else
        environmentProps="${environmentProps}, ANALYTICS_masternodes=$ANALYTICS_MASTER_IP:$ANALYTICS_COMM_PORT"
        echo "in master back up ip in else ${environmentProps} "
fi
args[10]="$volumes"

ports="$ANALYTICS_HTTPPORT"
args[11]="$ports"
args[12]="null"
args[13]="$environmentProps"
args[14]="null"
args[15]=${ANALYTICS_CONTAINER_GROUP_HOST}
args[16]=${ANALYTICS_CONTAINER_GROUP_DOMAIN}

#printf '%s\n' "${args[@]}"
#=====================================End of Preparing the array for the container group creation ======================================


createAnalyticsCtrResponse=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "createContainerGrp" ${args[1]} ${args[2]} ${args[3]} ${args[4]} ${args[5]} ${args[6]} ${args[7]} ${args[8]} ${args[9]} "$volumes" "$ports" ${args[12]} "$environmentProps" ${args[14]} ${args[15]} ${args[16]})
echo "Create Container group status : $createAnalyticsCtrResponse"
if  [[ $createAnalyticsCtrResponse == "" ]]  ; then
        echo "Error Occured in creation of analytics container group - Quitting!"
        exit 1
fi
if  [[ "${createAnalyticsCtrResponse}" == Error* ]]  ; then
        echo "Error Occured in creation of analytics container group - Quitting!"
        exit 1
fi
echo "Create Analytics Server Group Successful"

checkContainerGrpStatusWithWait "${BLUEMIX_CCS_HOST}" $access_token $spaceGUID $ANALYTICS_CONTAINER_GROUP_NAME "createAction"

echo "End of Create Analtyics Group"

