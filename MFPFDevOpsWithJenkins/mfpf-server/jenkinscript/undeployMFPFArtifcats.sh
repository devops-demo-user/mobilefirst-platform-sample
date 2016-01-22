#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
   
#!/usr/bin/bash

usage()
{
   echo
   echo " Umdeploys MobileFirst Adatper and Apps from  MobileFirst Server running on IBM Container on Bluemix "
   echo " ------------------------------------------------------------ "
   echo " This script undeploys the MobileFirst Adapter and Apps from a MobileFirst Server running on IBM Container in Bluemix"
   echo
   echo " Silent Execution (arguments provided as command-line arguments): "
   echo "   USAGE: undeployMFPFArtifcats.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "   -s | --server SERVER_IP The IP of the MobileFirst Platfor Server "
   echo "   -sp | --port SERVER_HTTPS_PORT    The https port that MobielFrist server listen to"
   echo "   -u | --mfpusername MFPF_ADMIN_USER_NAME 		The admin user name of MobileFirst Container"
   echo "   -p | --mfppassword MFPF_ADMIN_PASSWORD 		The admin user password of MobileFirst Container"
   echo "   -r | --root MFPF_ADMIN_ROOT         Contexzt root of mobilefirst Adminstartor"
   echo "   -rt | --runtime MFPF_RUNTIME_NAME  		MobileFirst runtime name"
   echo "   -ad | --adapter MFPF_ADAPTERS 		The adapter that are to be undeployed"
   echo "   -ap | --apps MFPF_APPS 		The worklight apps that are to be undeployed"
   echo "   -c | --cert CERT_FILE      certificate file eg: /opt/certificate/ca.rt"
   echo
   exit 1
}


validateParams()
{
        if [ -z "$SERVER_IP" ]
        then
                echo  Server Url is a mandartory argument that should be provided. Exiting...
                exit 0;
        fi

        if [ -z "$SERVER_PORT" ]
        then
                echo Server Port is a mandartory argument that should be provided. Exiting...
                exit 0;
        fi

        if [ -z "$MFPF_ADMIN_USER_NAME" ]
        then
                echo MFPF Admin Username field is empty. A mandatory argument must be specified. Exiting...
                exit 0
        fi

        if [ -z "$MFPF_ADMIN_PASSWORD" ]
        then
                echo MFPF Admin Password field is empty. A mandatory argument must be specified. Exiting...
                exit 0
        fi
        if [ -z "$MFPF_ADMIN_ROOT" ]
        then
                MFPF_ADMIN_ROOT="worklightadmin"
        fi

	if [ -z "$MFPF_RUNTIME_NAME" ]
    	then
        	echo  MFPF Admin user name is a mandartory argument that should be provided. Exiting...
        	exit 0;
    	fi

}

if [ "$1" = "-h" -o "$1" = "--help" ]
then
   usage
else
   while [ $# -gt 0 ]; do
      case "$1" in
         -s | --server)
            SERVER_IP="$2";
            shift
            ;;
         -sp | --port)
            SERVER_PORT="$2";
            shift
            ;;
         -u | --user)
            MFPF_ADMIN_USER_NAME="$2";
            shift
            ;;
         -p | --password)
            MFPF_ADMIN_PASSWORD="$2";
            shift
            ;;
         -r | --root)
            MFPF_ADMIN_ROOT="$2";
            shift
            ;;
         -rt | --runtime)
            MFPF_RUNTIME_NAME="$2";
            shift
            ;;
         -ad | --adapter)
            MFPF_ADAPTERS="$2";
            shift
            ;;
         -ap | --apps)
           MFPF_APPS="$2";
            shift
            ;;
         -c | --cert)
            CERT_PATH="$2";
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

echo "Arguments : "
echo "----------- "
echo "SERVER IP: " $SERVER_IP
echo "SERVER Port (HTTPS) : " $SERVER_PORT
echo "SERVER ADMIN USER NAME : " $MFPF_ADMIN_USER_NAME
echo "SERVER ADMIN PASSWORD : XXXXXXXXXXX" 
echo "SERVER_ADMIN_ROOT : " $MFPF_ADMIN_ROOT
echo "SERVER RUNTIME NAME : " $MFPF_RUNTIME_NAME
echo "SERVER ADAPTERS : " $MFPF_ADAPTERS
echo "SERVER APPS : " $MFPF_APPS
echo "CERT PATH : " $CERT_PATH
echo 

serverURL="https://$SERVER_IP:$SERVER_PORT"
echo "serverURL is $serverURL"
set -e 

if [ ! -z $MFPF_RUNTIME_NAME ] 
then
	# add the server first 
	
	OIFS=$IFS;
	IFS=",";
	
	adapterArray=($MFPF_ADAPTERS);
	for ((i=0; i<${#adapterArray[@]}; ++i)); do 
 		echo "adatper = " ${adapterArray[$i]} 
		#echo "will have to undeploy using curl the adapter named - ${adapterArray[$i]}"
		if [ -z $CERT_PATH ]
		then
			echo "curl -k -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/adapters/${adapterArray[$i]}?async=false"
			curl -k -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/adapters/${adapterArray[$i]}?async=false;
		else
			echo "curl --cacert $CERT_PATH -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/adapters/${adapterArray[$i]}?async=false"
			curl --cacert $CERT_PATH -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/adapters/${adapterArray[$i]}?async=false;
		fi	
	done
	
	echo "Undeployed the adapters "
	
	appArray=($MFPF_APPS);
	for ((i=0; i<${#appArray[@]}; ++i)); do 
	  	#echo "will have to undeploy using curl the app named - ${appArray[$i]}"
		if [ -z $CERT_PATH ]
		then
			 echo "curl -k -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/applications/${appArray[$i]}?async=false"
			 curl -k -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/applications/${appArray[$i]}?async=false
		else		
			echo "curl --cacert $CERT_PATH -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/applications/${appArray[$i]}?async=false"
		 	curl --cacert $CERT_PATH -u ${MFPF_ADMIN_USER_NAME}:${MFPF_ADMIN_PASSWORD} -i -H "Accept: application/json" -X DELETE ${serverURL}/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/${MFPF_RUNTIME_NAME}/applications/${appArray[$i]}?async=false
		fi
	done
	IFS=$OIFS;
	
else
	echo "No of app or adapters to be undeployed are empty"
		
fi 
set +e
