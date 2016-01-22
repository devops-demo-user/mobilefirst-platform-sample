#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash

usage() 
{
   echo 
   echo " Configuring the database service on Bluemix to use with MobileFirst Server image "
   echo " -------------------------------------------------------------------------------- "
   echo " Use this script to configure MobileFirst Server databases (administration and runtime)"
   echo " You must run this script once for administration database and then individually for each runtime."
   echo
   echo " Silent Execution (arguments provided as command line arguments):"
   echo "   USAGE: prepareserverdbs.sh <command line arguments> "
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
   echo "     -t | --type DB_TYPE              Bluemix database service type (sqldb | cloudantNoSQLDB)"
   echo "     -n | --name DB_SRV_NAME          Bluemix database service instance name"
   echo "     -pl | --plan DB_SRV_PLAN         Bluemix database service plan."
   echo "                                        For IBM SQL Database, the accepted values are sqldb_small, sqldb_free and sqldb_premium."
   echo "                                        For IBM Cloudant NoSQL DB, the accepted value is Shared."
   echo "     -an | --appname APP_NAME         Bluemix application name"
   echo "     -rt | --runtime AMIN_RUNTIME_NAME     (Optional) MobileFirst runtime name (required for configuring runtime databases only)"
   echo "     -sn | --schema ADMIN_SCHEMA_NAME      (Optional) Database schema name (defaults to WLADMIN for administration databases "
   echo "                                           or the runtime name for runtime databases)"
   echo "     					    Note : This option is ignored if sqldb_free plan is chosen - The default schema is used."
   echo 
   echo " Silent Execution (arguments loaded from file):"
   echo "   USAGE: prepareserverdbs.sh <path to the file from which arguments are read>"
   echo "          See args/prepareserverdbs.properties for the list of arguments."
   echo " Interactive Execution: "
   echo "   USAGE: prepareserverdbs.sh"
   echo
   exit 1
}

readParams()
{
    
        # Read the IBM Bluemix Database Type
        #-----------------------------------

        INPUT_MSG="Choose your Bluemix database service type. Enter 1 or 2 (mandatory).`echo $'\n1. sqldb ' $'\n2. cloudantNoSQLDB ' $'\n' $'\nDBtype>'`"
        ERROR_MSG="Incorrect option. Choose an option that represents your Bluemix database service type. Enter 1 or 2 (mandatory). `echo $'\n1. sqldb ' $'\n2. cloudantNoSQLDB ' $'\n' $'\nDBtype> '`"
        DB_TYPE=$(readDBTypeInputAsOptions "$INPUT_MSG" "$ERROR_MSG")
    
        # Read the IBM Bluemix Database Service Name.
        #--------------------------------------------
    	INPUT_MSG="Specify the name of your Bluemix database service. (mandatory) : "
        ERROR_MSG="Bluemix Database Service Name cannot be empty. Specify the name of your Bluemix database service. (mandatory) : "
        DB_SRV_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")

        # Read the IBM Bluemix Database Service Plan.
        #--------------------------------------------
        if [ "$DB_TYPE" = "sqldb" ]
        then
            INPUT_MSG="Choose your Bluemix database service plan for $DB_TYPE. Enter 1 or 2 (mandatory).`echo $'\n1. sqldb_free ' $'\n2. sqldb_premium ' $'\n' $'\nDBServicePlan>'`"
            ERROR_MSG="Incorrect option. Choose an option that represents your Bluemix database service plan for $DB_TYPE. Enter 1 or 2 (mandatory).`echo $'\n1. sqldb_free ' $'\n2. sqldb_premium ' $'\n' $'\nDBServicePlan>'`"
            DB_SRV_PLAN=$(readSQLDBServPlanOptions "$INPUT_MSG" "$ERROR_MSG")
        else
            DB_SRV_PLAN="Shared"
        fi
   
        # Read the IBM Bluemix Application Name
        #--------------------------------------
        INPUT_MSG="Specify the name of your Bluemix application (mandatory) : "
        ERROR_MSG="IBM Bluemix Application Name cannot be empty. Specify the name of your Bluemix application (mandatory) : "
        APP_NAME=$(fnReadInput "$INPUT_MSG" "$ERROR_MSG")
 
        # Read the Runtime / Project Name
        #-------------------------------
        read -p "Specify your runtime name or project name (If not specified, the script will perform the configuration of administration database) (optional) : " RUNTIME_NAME
 
        # Read the Database Schema Name 
        #---------------------------------
        if [ "$DB_SRV_PLAN" != "sqldb_free" ]
        then

                read -p "Specify the name of the database schema (defaults to WLADMIN for administration database or the runtime name for runtime databases) (optional) : " SCHEMA_NAME
        fi 
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

		if [ -z "$DB_TYPE" ]
		then
    			echo IBM Bluemix Database Type field is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
	
		if [ "$(validateDBType $DB_TYPE)" = "1" ]
	        then
        		echo  IBM Bluemix Database Type is not valid. Exiting...
	    		exit 0
   	 	fi
	
		if [ -z "$DB_SRV_NAME" ]
		then
    			echo IBM Bluemix Database Service Name field is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
	
		if [ -z "$DB_SRV_PLAN" ]
		then
    			echo IBM Bluemix Database Service Plan field is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
	
		if [ "$(validateDBServiceOption $DB_TYPE $DB_SRV_PLAN)" = "1" ]
    		then
        		echo  IBM Bluemix Database Service Plan for the $DB_TYPE database type is not valid. Exiting...
	    		exit 0
    		fi
	
		if [ -z "$APP_NAME" ]
		then
    			echo IBM Bluemix App Name field is empty. A mandatory argument must be specified. Exiting...
			exit 0
		fi
	
   		if [ -z "$RUNTIME_NAME" ]
   		then
   	 		if [ -z "$SCHEMA_NAME" ]
   	 		then
   	 			SCHEMA_NAME=WLADMIN
   	 		fi
   			else
   	 		if [ -z "$SCHEMA_NAME" ]
   	 		then
   	 			SCHEMA_NAME=$RUNTIME_NAME
   	 		fi
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
         -t | --type)
            DB_TYPE="$2";
            shift
            ;;
         -n | --name)
            DB_SRV_NAME="$2";
            shift
            ;;
         -pl | --plan)
            DB_SRV_PLAN="$2";
            shift
            ;;
         -an | --appname)
            APP_NAME="$2";
            shift
            ;;
         -rt | --runtime)
            RUNTIME_NAME="$2";
            shift
            ;;
         -sn | --schema)
            SCHEMA_NAME="$2";
            shift
            ;;
         *)
            usage
            ;;
      esac
      shift
   done
fi

trap - SIGINT

validateParams

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
echo "DB_TYPE : " $DB_TYPE
echo "DB_SRV_NAME : " $DB_SRV_NAME
echo "DB_SRV_PLAN : " $DB_SRV_PLAN
echo "APP_NAME : " $APP_NAME
echo "RUNTIME_NAME : " $RUNTIME_NAME
if [ "$DB_SRV_PLAN" != "sqldb_free" ]
then
    echo "SCHEMA_NAME : " $SCHEMA_NAME
else
    SCHEMA_NAME="SQLDB_FREE" # Send SQLDB_FREE so that the bluemix app recognises the plan
fi
echo 

#ice login -a $BLUEMIX_API_URL -H $BLUEMIX_CCS_HOST/containers -R $BLUEMIX_REGISTRY -u $BLUEMIX_USER -p $BLUEMIX_PASSWORD -o $BLUEMIX_ORG -s $BLUEMIX_SPACE

mfp container login -a $BLUEMIX_API_URL -u $BLUEMIX_USER -p $BLUEMIX_PASSWORD -o $BLUEMIX_ORG -s $BLUEMIX_SPACE


mfp container configdb -t $DB_TYPE -n $DB_SRV_NAME -p $DB_SRV_PLAN -a $APP_NAME -s $SCHEMA_NAME -f ../usr/config

# counter is maintained because if the db plan is sqldb_free, then only one runtime has to be added to the db.
COUNTER=0

cd ../usr/projects
projects=$(find . -mindepth 1 -maxdepth 1 -type d)
for DIR in $projects
do
	COUNTER=$(expr $COUNTER + 1)
	if [ "$DB_SRV_PLAN" != "sqldb_free" ]
	then
		mfp container configdb -t $DB_TYPE -n $DB_SRV_NAME -p $DB_SRV_PLAN -a $APP_NAME -s ${DIR##*/} -r ${DIR##*/} -f ../config
	else
		##ADMIN_SCHEMA_NAME="SQLDB_FREE" # Send SQLDB_FREE so that the bluemix app recognises the plan
		echo "-----------------------------db service plan is sqldb free"
		if [ $COUNTER -le 1 ]
		then
		    	SCHEMA_NAME="SQLDB_FREE"
		else 
		    	SCHEMA_NAME="SQLDB_FREE"
		    	DB_SRV_NAME=${DIR##*/}
		fi
		    
		mfp container configdb -t $DB_TYPE -n $DB_SRV_NAME -p $DB_SRV_PLAN -a $APP_NAME -s $SCHEMA_NAME -r ${DIR##*/} -f ../config
	fi
done

