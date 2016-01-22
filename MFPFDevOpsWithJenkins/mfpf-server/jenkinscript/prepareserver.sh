#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Preparing the MobileFirst Platform Foundation Server Image "
   echo " ------------------------------------------------------------ "
   echo " This script loads, customizes, tags, and pushes the MobileFirst Server image"
   echo " to the IBM Containers service on Bluemix."
   echo " Prerequisite: The prepareserverdbs.sh script is run before running this script."
   echo
   echo " Silent Execution (arguments provided as command-line arguments): "
   echo "   USAGE: prepareserver.sh <command-line arguments> "
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
   echo "   -t | --tag SERVER_IMAGE_TAG   Tag to be used for the customized MobileFirst Server image"
   echo "                                     Format: registryUrl/namespace/tag"
   echo "   -l | --loc PROJECT_LOC        (Optional) The location of the MobileFirst project"
   echo "                                     Multiple project locations can be delimited by commas."
   echo
   echo " Silent Execution (arguments loaded from file): "
   echo "   USAGE: prepareserver.sh <path to the file from which arguments are read> "
   echo "          See args/prepareserver.properties for the list of arguments."
   echo 
   echo " Interactive Execution: "
   echo "   USAGE: prepareserver.sh"
   echo
   exit 1
}

readParams()
{
    # Read the tag for the MobileFirst Server image
    #----------------------------------------------
    INPUT_MSG="Specify the tag for the MobileFirst Server image (mandatory) : "
    ERROR_MSG="Tag for MobileFirst Server image cannot be empty. Specify the tag for the image. (mandatory) : "
    SERVER_IMAGE_TAG=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
    
    read -p "Specify the comma-separated paths of the MobileFirst projects to be added to this image. If nothing is specified, only the projects copied to the usr/projects directory are added. (optional) : " PROJECT_LOC
   
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
}

repackageWarFile(){
   binDir=${1%/*}
   projectDir=${binDir%/*}
   mkdir -p $projectDir/tmp
   cd $projectDir/tmp
   jar -xf $1
   rm $1
   if [ -d "$projectDir/server/conf" ] && [ "$(ls -A --ignore=.git* $projectDir/server/conf)" ]
   then
      cp $projectDir/server/conf/* $projectDir/tmp/WEB-INF/classes/conf/
   fi
   if [ -d "$projectDir/server/lib" ] && [ "$(ls -A --ignore=.git* $projectDir/server/lib)" ]
   then
      cp $projectDir/server/lib/* $projectDir/tmp/WEB-INF/lib/
   fi   
   jar -cf $1 *
   cd $projectDir
   rm -rf $projectDir/tmp
}

copyProjects(){
   IFS=","
   for v in $PROJECT_LOC
   do
      projName=${v##*"/"}
      if [ -d "$v" ] && [ -e "$v/bin/$projName.war" ]
         then
         echo "Copying project artifacts."

         mkdir -p  ../usr/projects/$projName/bin
         cp -f $v/bin/$projName.war ../usr/projects/$projName/bin/
         adapter_files=$(find $v/bin/ -maxdepth 1 -name "*.adapter")
         if [ ! -z $adapter_files ]
         then
            echo "Copying adapters " $adapter_files
            cp -f $v/bin/*.adapter ../usr/projects/$projName/bin/
         fi

         wlapp_files=$(find $v/bin/ -maxdepth 1 -name "*.wlapp")
         if [ ! -z $wlapp_files ]
         then
            echo "Copying applications " $wlapp_files
            cp -f $v/bin/*.wlapp ../usr/projects/$projName/bin/
         fi
      else
         echo "$v is not a valid project path or it does not contain a runtime .war file in the $v/bin/ directory. Checking for .war files in the $v directory. Each .war file represents a runtime."
         war_files=$(find $v/ -maxdepth 1 -name "*.war")
         if [ ! -z $war_files ]
         then
            for f in $v/*.war
            do
               projName=${f##*"/"}
               projName=${projName::$((${#projName}-4))}
               mkdir -p  ../usr/projects/$projName/bin
               cp -f $f ../usr/projects/$projName/bin/
            done
         else
            echo "Directory $v does not contain any runtime .war file."
            exit 1
         fi
      fi
   done
}

buildProjects()
{
   currentDir=`pwd`
   for dir in ../usr/projects/*; do      
      projectDir=$dir
      projectName=${dir##*/}      
      for file in $projectDir/bin/*; do                 
         if [[ ${file##*.} == war ]]
            then             
               warFilePath=$currentDir/$file
               relativeWarPath="usr/projects/$projectName/bin/${projectName}.war"
               #repackageWarFile $warFilePath
               cd $currentDir

               # Update the Dockerfile with the war location
               appPath=/opt/ibm/wlp/usr/servers/worklight/apps/
               RET_VAL=`grep -q "COPY $relativeWarPath $appPath" ../Dockerfile ; echo $?`
               if [ ! $RET_VAL -eq 0 ]
               then
                  echo "COPY $relativeWarPath $appPath" >> ../Dockerfile
               fi               
               break
         fi
      done
   done
}

migrateProjects()
{
   #### Migrate the project WAR files
   # check if user has overridden JAVA_HOME . else set to standard location
   if [ -z "$JAVA_HOME" ]
   then
      # export JAVA_HOME = "/usr/java"
      echo "JAVA_HOME not set. Please set JAVA_HOME for MFP migration to continue"
      exit 1
   else
      echo "JAVA_HOME:" $JAVA_HOME
   fi

   for d in ../usr/projects/*/
   do
       if [[ -d $d ]]; then
         for war in $d/bin/*.war; do
            echo "******* Migrating:" $war "********"
            ../../mfpf-libs/apache-ant-1.9.4/bin/ant -f migrate.xml -Dwarfile=$war
         done
       fi
   done
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
    
    currentDir=`pwd`
    for dir in ../usr/projects/*; do
    	projectDir=$dir
    	projectName=${dir##*/}
    	for file in $projectDir/bin/*; do
    		if [[ ${file##*.} == war ]]
    		then
    			if [[ -d ${projectDir}/tmp  && ! -z ${projectDir} ]]
    			then
    				rm -rf ${projectDir}/tmp
    			fi
    		    break
    		fi
    	done
    done
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
         -t | --tag)
            SERVER_IMAGE_TAG="$2";
            shift
            ;;
         -l | --loc)
            PROJECT_LOC="$2";
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
echo "BLUEMIX_API_URL : " $BLUEMIX_API_URL
echo "BLUEMIX_REGISTRY : " $BLUEMIX_REGISTRY
echo "BLUEMIX_CCS_HOST : " $BLUEMIX_CCS_HOST
echo "BLUEMIX_USER : " $BLUEMIX_USER
echo "BLUEMIX_PASSWORD : " XXXXXXXX
echo "BLUEMIX_ORG : " $BLUEMIX_ORG
echo "BLUEMIX_SPACE : " $BLUEMIX_SPACE
echo "SERVER_IMAGE_TAG : " $SERVER_IMAGE_TAG
echo "PROJECT_LOC : " $PROJECT_LOC
echo

##TODO:commening copy and build project as of now, Once the issue with build version is fixed in worklight.properties, uncoment
#copyProjects
buildProjects
migrateProjects

mv ../../dependencies ../dependencies
mv ../../mfpf-libs ../mfpf-libs
cp -rf ../../licenses ../licenses

if [ -f ../../mfpf-server.tar.gz ]
then
        rm -rf ../../mfpf-server.tar.gz
fi

cd ..

tar -zcvf  ../mfpf-server.tar.gz .

cd jenkinscript
mv ../dependencies ../../dependencies
mv ../mfpf-libs ../../mfpf-libs
rm -rf ../licenses


COUNTER=40
while [ $COUNTER -gt 0 ]
do
 	if [ -f ../../mfpf-server.tar.gz ]
    	then
            	break
    	fi

    	# Allow to sleep for 40s.
    	sleep 5s

    	COUNTER=$(expr $COUNTER - 1)
done

echo "Building the MobileFirst Server image : " $SERVER_IMAGE_TAG

if [  -f ../../mfpf-server.tar.gz ]; then
        mfp_server_push=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "buildImage" "$BLUEMIX_CCS_HOST/build" $access_token $spaceGUID $SERVER_IMAGE_TAG  ../../mfpf-server.tar.gz)
        if  [[ $mfp_server_push == Error* ]]  ; then
                echo "Error Occured in build of image - Quitting!"
                exit 1
        fi
        echo "Status of MobileFrist Starter Image build and Push : $mfp_server_push"
fi

mfp_server_push=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getImageList" "$BLUEMIX_CCS_HOST" $access_token $spaceGUID )


