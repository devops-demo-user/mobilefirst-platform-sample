#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash


usage() 
{
   echo 
   echo " Removing a project from the MobileFirst Server Image "
   echo " -------------------------------------------------------------------------- "
   echo " This script removes a project from the IBM MobileFirst Platform Foundation configuration."
   echo " After running this script, then run the prepareserver.sh script."
   echo
   echo " Silent Execution (arguments provided as command-line arguments) : "
   echo "   USAGE: removeproject.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "     -a | --api BLUEMIX_API_URL       (Optional) Bluemix API endpoint. Defaults to https://api.ng.bluemix.net"
   echo "     -r | --registry BLUEMIX_REGISTRY (Optional) IBM Containers Registry Host"
   echo "                                      Defaults to registry.ng.bluemix.net"
   echo "     -h | --host BLUEMIX_CCS_HOST     (Optional) IBM Containers Cloud Service Host"
   echo "                                      Defaults to https://containers-api.ng.bluemix.net/v3/containers"
   echo "     -u | --user BLUEMIX_USER         Bluemix user ID or email address (If not provided, assumes ICE is already logged-in.)"
   echo "     -p | --password BLUEMIX_PASSWORD Bluemix password"
   echo "     -o | --org BLUEMIX_ORG           Bluemix organization"
   echo "     -s | --space BLUEMIX_SPACE       Bluemix space"
   echo "     -c | --cert CERT_FILE	       Certificate file eg : /opt/certificate/ca.crt"
   echo "     -rt | --runtime RUNTIME_NAME             The name of the runtime to be removed."
   echo "     -i | --ip SERVER_IP                     The IP address the MobileFirst Server container is bound to."
   echo "     -sp | --port SERVER_PORT                 The HTTP or HTTPS port number exposed on the MobileFirst Server container."
   echo "    -lu | --libertyadminusername LIBERTY_ADMIN_USERNAME User name of the Liberty administrator role"
   echo "    -lp | --libertyadminpassword LIBERTY_ADMIN_PASSWORD Password of the Liberty administrator role"
   echo "    -au | --mfpfadminusername MFPF_ADMIN_USERNAME     User name of MobileFirst Server administrator"
   echo "    -ap | --mfpfadminpassword MFPF_ADMIN_PASSWORD    Password of MobileFirst Server administrator"
   echo "     -d | --deletedata DELETE_RUNTIME_DATA   (Optional) Confirmation to delete the project-related data"
   echo "                                               from the database. Accepted values are Y or N (default)."
   echo "     -an | --appname APP_NAME                The Bluemix application name."
   echo "      -n | --servicename DB_SRV_NAME         The Bluemix database service instance name."
   echo "     -sn | --schema SCHEMA_NAME              (Optional) Schema name (defaults to runtime name for runtime database)"
   echo "     -ar | --adminroot MFPF_ADMIN_ROOT        (Optional) Admin context path of the MobileFirst Server. (defaults to worklightadmin if not specified)"
   echo
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: removeproject.sh <path to the file from which arguments are read>"
   echo "          See args/removeproject.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: removeproject.sh"
   echo
   exit 1
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

   if [ -z "$RUNTIME_NAME" ]
   then
         echo RUNTIME_NAME is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$SERVER_IP" ]
   then
         echo SERVER_IP is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

	if [ "$(valid_ip $SERVER_IP)" = "1" ]
   then
          echo SERVER_IP is incorrect. Exiting...
          exit 0
   fi

   if [ -z "$SERVER_PORT" ]
   then
         echo SERVER_PORT is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

    if [ "$(isNumber $SERVER_PORT)" = "1" ]
    then
         echo Invalid SERVER_PORT. Exiting...
         exit 0
    fi

   if [ -z "$LIBERTY_ADMIN_USERNAME" ]
   then
         echo LIBERTY_ADMIN_USERNAME is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$LIBERTY_ADMIN_PASSWORD" ]
   then
         echo LIBERTY_ADMIN_PASSWORD is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$MFPF_ADMIN_USERNAME" ]
   then
         echo MFPF_ADMIN_USERNAME is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$MFPF_ADMIN_PASSWORD" ]
   then
         echo MFPF_ADMIN_PASSWORD is empty. A mandatory argument must be specified. Exiting...
         exit 0
   fi

   if [ -z "$DELETE_RUNTIME_DATA" ] 
   then     
      DELETE_RUNTIME_DATA="N"
   fi
   
   if [ "$DELETE_RUNTIME_DATA" = "Y" ] || [ "$DELETE_RUNTIME_DATA" = "y" ]
   then 
      
      if [ -z "$DB_SRV_NAME" ]
      then
            echo IBM Bluemix Database Service Name field is empty. A mandatory argument must be specified. Exiting...
            exit 0
      fi

      if [ -z "$APP_NAME" ]
      then
         echo IBM Bluemix App Name field is empty. A mandatory argument must be specified. Exiting...
         exit 0
      fi
      
      if [ -z "$SCHEMA_NAME" ]
         then
            SCHEMA_NAME=$RUNTIME_NAME
         fi
   fi

   if [ -z "$MFPF_ADMIN_ROOT" ]
   then
      MFPF_ADMIN_ROOT="worklightadmin"
   fi
}

cd "$( dirname "$0" )"

source ../../jenkins-common-scripts/common.sh

if [ "$1" = "-h" -o "$1" = "--help" ]
then
   usage
else
   while [ $# -gt 0 ]; do
      case "$1" in
         -a | --api)
            BLUEMIX_API_URL="$2";
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
         -h | --host)
            BLUEMIX_CCS_HOST="$2";
            shift
            ;;
         -c | --cert)
            CERT_PATH="$2";
            shift
            ;;
         -rt | --runtime)
            RUNTIME_NAME="$2";
            shift
            ;;
         -i | --ip)
            SERVER_IP="$2";
            shift
            ;;
         -sp | --port)
            SERVER_PORT="$2";
            shift
            ;;
         -lu | --libertyadminusername)
            LIBERTY_ADMIN_USERNAME="$2";
            shift
            ;;
         -lp | --libertyadminpassword)
            LIBERTY_ADMIN_PASSWORD="$2";
            shift
            ;;
         -au | --mfpfadminusername)
            MFPF_ADMIN_USERNAME="$2";
            shift
            ;;
         -ap | --mfpfadminpassword)
            MFPF_ADMIN_PASSWORD="$2";
            shift
            ;;
         -d | --deletedata)
            DELETE_RUNTIME_DATA="$2";
            shift
            ;;
         -an | --appname)
            APP_NAME="$2";
            shift
            ;;
         -n | --servicename)
         	DB_SRV_NAME="$2";
         	shift
         	;;
         -sn | --schema)
         	SCHEMA_NAME="$2";
         	shift
         	;;
         -ar | --adminroot)
            MFPF_ADMIN_ROOT="$2";
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

set -x
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
echo "RUNTIME_NAME : " $RUNTIME_NAME
echo "SERVER CONTAINER IP : " $SERVER_IP
echo "SERVER CONTAINER PORT : " $SERVER_PORT
echo "LIBERTY ADMIN USER NAME : " $LIBERTY_ADMIN_USERNAME
echo "LIBERTY ADMIN PASSWORD : XXXXXXXX " 
echo "MFPF ADMIN USER NAME : " $MFPF_ADMIN_USERNAME
echo "MFPF ADMIN PASSWORD : XXXXXXXX "
echo "DELETE_RUNTIME_DATA : " $DELETE_RUNTIME_DATA
echo "MFPF_ADMIN_ROOT : " $MFPF_ADMIN_ROOT
echo "CERT PATH : " $CERT_PATH

if [ "$DELETE_RUNTIME_DATA" = "Y" ] || [ "$DELETE_RUNTIME_DATA" = "y" ] 
then
   echo "APP_NAME : " $APP_NAME
   echo "DB_SRV_NAME : " $DB_SRV_NAME
   echo "SCHEMA_NAME : " $SCHEMA_NAME
fi

echo 

echo "Deleting the configuration files of the $RUNTIME_NAME project..."
rm -f ../usr/config/${RUNTIME_NAME}.xml

appPath=/opt/ibm/wlp/usr/servers/worklight/apps/
relativeWarPath="usr/projects/${RUNTIME_NAME}/bin/${RUNTIME_NAME}.war"

line=$(grep -n "COPY $relativeWarPath $appPath" ../Dockerfile | cut -d : -f 1 )
if [ ! -z $line ] 
then 
   cd ..
      
   sedResult = $(sed -i .bk  "$line"'d' Dockerfile)
   rm -rf *.bk
   echo "sedResult is $sedResult"
   echo "Removed project references from the Dockerfile."
   cd jenkinscript
fi            

if [ "$DELETE_RUNTIME_DATA" = "Y" ] || [ "$DELETE_RUNTIME_DATA" = "y" ]
then
	echo "Deleting the $RUNTIME_NAME project related data from the database" 
	mfp container delete -n $DB_SRV_NAME -a $APP_NAME -s $SCHEMA_NAME -d "worklight"
fi

if [ -z $CERT_PATH ]
then
        curl_cmd="curl -k";
else
        curl_cmd="curl --cacert $CERT_PATH";
fi

echo "Stopping the $RUNTIME_NAME project on the container..."

$curl_cmd -s -u ${MFPF_ADMIN_USERNAME}:${MFPF_ADMIN_PASSWORD} -H "Content-Type : application/json" -X POST https://${SERVER_IP}:${SERVER_PORT}/IBMJMXConnectorREST/mbeans/WebSphere:name=${RUNTIME_NAME},service=com.ibm.websphere.application.ApplicationMBean/operations/stop -d {} 

echo "Deleting the data related to $RUNTIME_NAME project from the management database"
$curl_cmd -s -u ${MFPF_ADMIN_USERNAME}:${MFPF_ADMIN_PASSWORD} -X DELETE https://${SERVER_IP}:${SERVER_PORT}/${MFPF_ADMIN_ROOT}/management-apis/1.0/runtimes/${RUNTIME_NAME}/lock 

$curl_cmd -s -u ${MFPF_ADMIN_USERNAME}:${MFPF_ADMIN_PASSWORD} -X DELETE https://${SERVER_IP}:${SERVER_PORT}/${MFPF_ADMIN_ROOT}/management-apis/1.0/runtimes/${RUNTIME_NAME} 

echo
echo "Removed Runtime from the Container"
:
