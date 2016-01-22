#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 
#!/usr/bin/bash
#set -x

#main
    		
#set -e
usage()
{
   echo
   echo " Removes a MobileFirst Container Group from Bluemix Container"
   echo " -------------------------------------------------------------------------- "
   echo " This script removes MobileFirst Server/Analytics container group running on Bluemix Container."
   echo
   echo " Silent Execution (arguments provided as command-line arguments) : "
   echo "   USAGE: removeContainerGroup.sh <command-line arguments> "
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
   echo "     -n | --name SERVER_CONTAINER_GROUP_NAME  Name of the MobileFirst Server container"
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
	if [ -z "$SERVER_CONTAINER_GROUP_NAME" ]
	then
		echo Server Container Name is empty. A mandatory argument must be specified. Exiting...
		exit 0
	fi
}

source $WORKSPACE/MFP_Container/jenkins-common-scripts/common.sh

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
         -n | --name)
            SERVER_CONTAINER_GROUP_NAME="$2";
            shift
            ;;
         *)
            usage
            ;;
      esac
      shift
   done
fi

source $WORKSPACE/MFP_Container/jenkins-common-scripts/initenv.sh -u $BLUEMIX_USER -p $BLUEMIX_PASSWORD -o $BLUEMIX_ORG -s $BLUEMIX_SPACE
source $WORKSPACE/MFP_Container/jenkins-common-scripts/ice_common_commands.sh
validateParams

getCtrGrpState "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $SERVER_CONTAINER_GROUP_NAME
echo "----------------------------------- state in initial is $state"

if [[ "$state" == Error* ]]; then
        echo "Could not get the state of the container group.  Quitting!"
        exit 1;
fi
if [[ "$state" == 404* ]]; then
        echo "Container Group does not exist already. "
else
        echo "Container Group exist.  Check the status"
        stopResult=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer 'stopDeleteCtrGrp' "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $SERVER_CONTAINER_GROUP_NAME)
        echo "stopResult in script is $stopResult"
        if  [[ $stopResult == Error* ]]  ; then
                echo "Error Occured in container group stop  - Quitting!"
                exit 1
        fi
        echo "----------------------------------- Container group stopped"

        checkContainerGrpStatusWithWait "$BLUEMIX_CCS_HOST" $access_token $spaceGUID $SERVER_CONTAINER_GROUP_NAME "removeAction"
fi


echo "Finished"

