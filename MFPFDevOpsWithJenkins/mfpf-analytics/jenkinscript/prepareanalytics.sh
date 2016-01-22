#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  

#!/usr/bin/bash

usage() 
{
   echo 
   echo " Preparing the MobileFirst Operational Analytics image "
   echo " ----------------------------------------------------- "
   echo " This script loads, customizes, tags, and pushes the MobileFirst Operational"
   echo " Analytics image on the IBM Containers service on Bluemix."
   echo " Prerequisite: You must run the initenv.sh script before running this script."
   echo
   echo " Silent Execution (arguments provided as command line arguments): "
   echo "   USAGE: prepareanalytics.sh <command-line arguments> "
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
   echo "   -t | --tag ANALYTICS_IMAGE_TAG  Tag to be used for tagging the analytics image."
   echo "                                     Format: registryUrl/namespace/tag"
   echo
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: prepareanalytics.sh <path to the file from which arguments are read> "
   echo "          See args/prepareanalytics.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: prepareanalytics.sh"
   echo
   exit 1
}

readParams()
{
   
   # Read the tag for the analytics image
   #-------------------------------------
   INPUT_MSG="Specify the tag for the analytics image (mandatory) : "
   ERROR_MSG="Tag for analytics image cannot be empty. Specify the tag for the analytics image (mandatory) : "
   ANALYTICS_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
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
}

clean_up() {
	# Perform clean up before exiting
	cd "${absoluteScriptDir}"
        
    if [ -d ../dependencies ]
    then
        mv ../dependencies ../../dependencies
    fi
    if [ -d ../mfpf-libs ]
    then
        mv ../mfpf-libs ../../mfpf-libs
    fi
    if [ -d ../licenses ]
    then 
        rm -rf ../licenses
    fi
    
}


cd "$( dirname "$0" )"

source ../../jenkins-common-scripts/common.sh

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
         -l | --location)
            ANALYTICS_IMAGE_LOCATION="$2";
            shift
            ;;
         -t | --tag)
            ANALYTICS_IMAGE_TAG="$2";
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
trap clean_up 0 1 2 3 15

scriptDir=`dirname $0`

absoluteScriptDir=`pwd`/${scriptDir}/

echo "Arguments : "
echo "----------- "
echo 
echo "ANALYTICS_IMAGE_TAG : " $ANALYTICS_IMAGE_TAG
echo 

mv ../../dependencies ../dependencies
mv ../../mfpf-libs ../mfpf-libs
cp -rf ../../licenses ../licenses

#addSshToDockerfile ../usr ../Dockerfile

if [ -f ../../mfpf-analytics.tar.gz ]
then
        rm -rf ../../mfpf-analytics.tar.gz
fi

cd ..

tar -zcvf ../mfpf-analytics.tar.gz .

cd jenkinscript
mv ../dependencies ../../dependencies
mv ../mfpf-libs ../../mfpf-libs
rm -rf ../licenses
	
	
echo "Building the Analytics Image : " $ANALYTICS_IMAGE_TAG

COUNTER=40
while [ $COUNTER -gt 0 ]
do
 if [ -f ../../mfpf-analytics.tar.gz ]
    then
	echo "File exist"
      	break
    fi

    # Allow to sleep for 40s.
    sleep 5s

    COUNTER=$(expr $COUNTER - 1)
done


#cd $PLUGIN_HOME/MFPContainerFiles/mfpf-analytics/scripts

if [  -f ../../mfpf-analytics.tar.gz ]; then
        mfp_analytics_push=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "buildImage" "$BLUEMIX_CCS_HOST/build" $access_token $spaceGUID $ANALYTICS_IMAGE_TAG ../../mfpf-analytics.tar.gz)
        echo "Status of Analtics image build and push : $mfp_analytics_push"
        if  [[ $mfp_analytics_push == Error* ]]  ; then
                echo "Error Occured in build of image - Quitting!"
                exit 1
        fi

fi

echo "End of Prepreare Analytics Server Build and Push"
