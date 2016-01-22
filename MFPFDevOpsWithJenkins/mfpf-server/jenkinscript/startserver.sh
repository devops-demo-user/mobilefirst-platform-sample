#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Running a MobileFirst Platform Foundation Server Image as a Container "
   echo " --------------------------------------------------------------------------------- "
   echo " This script runs the MobileFirst Server image as a container"
   echo " on the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareserver.sh script must be run before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments):"
   echo "   USAGE: startserver.sh <command line arguments> "
   echo "     -a | --api BLUEMIX_API_URL       (Optional) Bluemix API endpoint. Defaults to https://api.ng.bluemix.net"
   echo "     -r | --registry BLUEMIX_REGISTRY (Optional) IBM Containers Registry Host"
   echo "                                      Defaults to registry.ng.bluemix.net"
   echo "     -h | --host BLUEMIX_CCS_HOST     (Optional) IBM Containers Cloud Service Host"
   echo "                                      Defaults to https://containers-api.ng.bluemix.net/v3/containers"
   echo "     -u | --user BLUEMIX_USER         Bluemix user ID or email address (If not provided, assumes ICE is already logged-in.)"
   echo "     -p | --password BLUEMIX_PASSWORD Bluemix password"
   echo "     -o | --org BLUEMIX_ORG           Bluemix organization"
   echo "     -s | --space BLUEMIX_SPACE       Bluemix space"
   echo "     -t | --tag SERVER_IMAGE_TAG        Tag to be used for tagging the MobileFirst Server image"
   echo "     -n | --name SERVER_CONTAINER_NAME  Name of the MobileFirst Server container"
   echo "     -i | --ip SERVER_IP                IP address that the MobileFirst Server container should be bound to"
   echo "     -an | --appName APP_NAME           (Optional) Bluemix application name that should be bound to the container"
   echo "     -hp | --http EXPOSE_HTTP            (Optional) Expose HTTP Port. Accepted values are Y (default) or N"
   echo "     -hs | --https EXPOSE_HTTPS          (Optional) Expose HTTPS Port. Accepted values are Y (default) or N"
   echo "     -m | --memory SERVER_MEM           (Optional) Assign a memory size limit to the container in megabytes (MB)"
   echo "                                          Accepted values are 1024 (default), 2048,..."
   echo "     -se | --ssh SSH_ENABLE             (Optional) Enable SSH for the container. Accepted values are Y (default) or N"
   echo "     -sk | --sshkey SSH_KEY             (Optional) SSH Key to be injected into the container"
   echo "     -tr | --trace TRACE_SPEC           (Optional) Trace specification to be applied to MobileFirst Server"
   echo "     -ml | --maxlog MAX_LOG_FILES       (Optional) Maximum number of log files to maintain before overwriting"
   echo "     -ms | --maxlogsize MAX_LOG_FILE_SIZE (Optional) Maximum size of a log file"
   echo "     -v | --volume ENABLE_VOLUME        (Optional) Enable mounting volume for container logs"
   echo "                                          Accepted values are Y or N (default)"
   echo "     -e | --env MFPF_PROPERTIES         (Optional) MobileFirst Platform Foundation properties as comma-separated key:value pairs"
   echo "					   Example: wl.analytics.url:http://127.0.0.1/analytics-service/v2,wl.analytics.console.url:http://127.0.0.1/analytics/console" 
   echo 
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: startserver.sh <path to the file from which arguments are read>"
   echo "          See args/startserver.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: startserver.sh"
   echo
   exit 1
}

readParams()
{
        
   # Read the tag for the MobileFirst Server image
   #----------------------------------------------
   INPUT_MSG="Specify the tag for the MobileFirst Server image (mandatory) : "
   ERROR_MSG="Tag for MobileFirst Server image cannot be empty. Specify the tag for the MobileFirst Server image (mandatory) : "
   SERVER_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the name of the container 
   #-------------------------------
   INPUT_MSG="Specify the name of the container (mandatory) : " 
   ERROR_MSG="Container name cannot be empty. Specify the name of the container (mandatory) : "
   SERVER_CONTAINER_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

   # Read the IP address for the MobileFirst Server container 
   #---------------------------------------------------------
   INPUT_MSG="Specify the IP address for the MobileFirst Server container (mandatory) : "
   ERROR_MSG="Incorrect IP address. Specify the correct IP address for the MobileFirst Server container (mandatory) : " 
   SERVER_IP=$(fnReadIP "$INPUT_MSG" "$ERROR_MSG")

   # Read the Bluemix application name
   #-----------------------------------
   read -p "Specify the Bluemix application name that should be bound to the container (optional) : " APP_NAME

   # Expose HTTP/HTTPS Port
   #------------------------
   INPUT_MSG="Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : " 
   ERROR_MSG="Input should be either Y or N. Expose HTTP Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTP=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   INPUT_MSG="Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : " 
   ERROR_MSG="Input should be either Y or N. Expose HTTPS Port. Accepted values are Y or N. The default value is Y. (optional) : "
   EXPOSE_HTTPS=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   # Read the memory size for the MobileFirst Server container
   #-----------------------------------------
   INPUT_MSG="Specify the memory size limit (in MB) for the MobileFirst Server container. Accepted values are 1024, 2048,... The default value is 1024 (optional) : "
   ERROR_MSG="Error due to non-numeric input. Specify a valid value. Valid values are 1024, 2048,... The default value is 1024 (optional) : "
   SERVER_MEM=$(fnReadNumericInput "$INPUT_MSG" "$ERROR_MSG" "1024")

   # Read the SSH/Mounting Volume/Trace Spec details
   #------------------------------------------------
   INPUT_MSG="Enable SSH For the MobileFirst Server container. Accepted values are Y or N. The default value is Y. (optional) : "
   ERROR_MSG="Input should be either Y or N. Enable SSH For the MobileFirst Server container. Accepted values are Y or N. The default value is Y. (optional) : "
   SSH_ENABLE=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "Y")

   if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
   then
      read -p "Provide an SSH Key to be injected into the container. Provide the contents of your id_rsa.pub file (optional): " SSH_KEY
   fi
 
   INPUT_MSG="Enable mounting volume for the MobileFirst Server container logs. Accepted values are Y or N. The default value is N (optional) : " 
   ERROR_MSG="Input should be either Y or N. Enable mounting volume for the MobileFirst Server container logs. Accepted values are Y or N. The default value is N (optional) : " 
   ENABLE_VOLUME=$(readBoolean "$INPUT_MSG" "$ERROR_MSG" "N")
   
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
   read -p "Specify related MobileFirst Platform Foundation properties as comma-separated key:value pairs (optional) : " MFPF_PROPERTIES

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

		if [ -z "$SERVER_IMAGE_TAG" ]
		then
    			echo Server Image Tag is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
	
		if [ -z "$SERVER_CONTAINER_NAME" ]
		then
    			echo Server Container Name is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi

		if [ -z "$SERVER_IP" ]
		then
    			echo Server Container IP Address field is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
	
		if [ "$(valid_ip $SERVER_IP)" = "1" ]
		then
		    	echo Server Container IP Address is incorrect. Exiting...
	        	exit 0
		fi
		if [ -z "$SERVER_MEM" ]
		then 
    			SERVER_MEM=1024
   		fi

		if [ "$(isNumber $SERVER_MEM)" = "1" ]
    		then
        		echo  Required Server Container Memory must be a number. Exiting...
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
        		echo  Invalid Value for EXPOSE_HTTPS. Values must be either Y / N. Exiting...
	    	exit 0
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

# The volume name and the path in the container that the volume will be mounted
SYSVOL_NAME=sysvol
LIBERTYVOL_NAME=libertyvol
SYSVOL_PATH=/var/log/rsyslog
LIBERTYVOL_PATH=/opt/ibm/wlp/usr/servers/worklight/logs

cd "$( dirname "$0" )"

source ../../jenkins-common-scripts/common.sh
source ../usr/env/server.env
  
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
            SERVER_IMAGE_TAG="$2";
            shift
            ;;
         -n | --name)
            SERVER_CONTAINER_NAME="$2";
            shift
            ;;
         -m | --memory)
            SERVER_MEM="$2";
            shift
            ;;
         -i | --ip)
            SERVER_IP="$2";
            shift
            ;;
         -an | --appName)
            APP_NAME="$2";
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
         -hp | --http)
            EXPOSE_HTTP="$2";
            shift
            ;;
         -hs | --https)
            EXPOSE_HTTPS="$2";
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
echo "SERVER_IMAGE_TAG : " $SERVER_IMAGE_TAG
echo "SERVER_CONTAINER_NAME : " $SERVER_CONTAINER_NAME
echo "SERVER_MEM : " $SERVER_MEM
echo "SERVER_IP : " $SERVER_IP
echo "APP_NAME : " $APP_NAME
echo "EXPOSE_HTTP : " $EXPOSE_HTTP
echo "EXPOSE_HTTPS : " $EXPOSE_HTTPS
echo "SSH_ENABLE : " $SSH_ENABLE
echo "ENABLE_VOLUME : " $ENABLE_VOLUME
echo "SSH_KEY : " $SSH_KEY
echo "TRACE_SPEC : " $TRACE_SPEC
echo "MAX_LOG_FILES : " $MAX_LOG_FILES
echo "MAX_LOG_FILE_SIZE : " $MAX_LOG_FILE_SIZE
echo "MFPF_PROPERTIES : " $MFPF_PROPERTIES
echo 

rgs[0]="createContainer"
args[1]=$BLUEMIX_CCS_HOST
args[2]=$access_token
args[3]=$spaceGUID
args[4]=$SERVER_IMAGE_TAG
args[5]=$SERVER_CONTAINER_NAME
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


echo "Environmentprops : $environmentProps"
args[7]="$environmentProps"
args[8]="null"

if [ ! -z "$SSH_KEY" ] && ([ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ])
then
        KeyName=$SSH_ENABLE
else
        KeyName="null"
fi
args[9]="$KeyName"
if [ "$SSH_ENABLE" = "Y" ] || [ "$SSH_ENABLE" = "y" ]
then
   ports="22"
fi

if [ "$EXPOSE_HTTP" = "Y" ] || [ "$EXPOSE_HTTP" = "y" ]
then
        if [ -z "$ports" ]; then
            	echo "ports is empty"
            	ports="$MFPF_SERVER_HTTPPORT"
        else
        	ports="$ports , $MFPF_SERVER_HTTPPORT"
        fi
fi

if [ "$EXPOSE_HTTPS" = "Y" ] || [ "$EXPOSE_HTTPS" = "y" ]
then
        if [ -z "$ports" ]; then
        	echo "ports is empty"
                ports="$MFPF_SERVER_HTTPSPORT"
        else
            	ports="$ports, $MFPF_SERVER_HTTPSPORT"
        fi
fi
args[10]="$ports"
args[11]="null"

if [ ! -z "$APP_NAME" ] || [ "$APP_NAME" = "y" ]
then
        appName="$APP_NAME"
else
        appName="null"
fi
args[12]="$appName"

if [ "$ENABLE_VOLUME" = "Y" ] || [ "$ENABLE_VOLUME" = "y" ]
then
   createVolumes
   volumes="$SYSVOL_NAME:$SYSVOL_PATH, $LIBERTYVOL_NAME:$LIBERTYVOL_PATH"
else
    volumes="null"
fi
args[13]="$volumes"
args[14]=0
args[15]="null"


#printf '%s\n' "${args[@]}"


createCtrResponse=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "createContainer" ${args[1]} ${args[2]} ${args[3]} ${args[4]} ${args[5]} ${args[6]} "$environmentProps" ${args[8]} ${args[9]} "$ports" ${args[11]} ${args[12]} "$volumes" ${args[14]} ${args[15]})
echo "Create container response : $createCtrResponse"
if  [[ $createCtrResponse == Error* ]]  ; then
        echo "Error Occured in creation of container - Quitting!"
        exit 1
fi
echo "Create Server Successful"

ctrId=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer 'getCtrIdWithName' "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $SERVER_CONTAINER_NAME)

checkContainerStatusWithWait "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $SERVER_CONTAINER_NAME "ipAction"

ipAssignResponse=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "assignIP" "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $ctrId $SERVER_IP)
#echo "Ip assign is $ipAssignResponse"
if  [[ $ipAssignResponse == Error* ]]  ; then
        echo "Error Occured in ip assignment to container - Quitting!"
        exit 1
fi
echo "Container successfully created and IP is bound"

set +e

