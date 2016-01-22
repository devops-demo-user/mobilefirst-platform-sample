#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
   
#!/usr/bin/bash


usage()
{
   echo
   echo " Deploys MobileFirst Adatper and Apps to MobileFirst Server running on IBM Container on Bluemix "
   echo " ------------------------------------------------------------ "
   echo " This script pushes the MobileFirst Adapter and Apps to MobileFirst Server running on IBM Container in Bluemix"
   echo
   echo " Silent Execution (arguments provided as command-line arguments): "
   echo "   USAGE: prepareserver.sh <command-line arguments> "
   echo "   command-line arguments: "
   echo "   -s | --server SERVER_IP	The URL of the MobileFirst Container Image"
   echo "   -sp | --port SERVER_PORT	The port that MobielFrist server listen to"
   echo "   -u | --user	MFPF_ADMIN_USERNAME	User name of MobileFirst Server administrator"	
   echo "   -p | --password MFPF_ADMIN_PASSWORD Password of MobileFirst Server Adminstrator"
   echo "   -r | --root MFPF_ADMIN_ROOT 	Contexzt root of mobilefirst Adminstartor" 
   echo "   -c | --cert CERT_FILE	certificate file eg: /opt/certificate/ca.rt"
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

        if [ -z "$MFPF_ADMIN_USERNAME" ]
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
            MFPF_ADMIN_USERNAME="$2";
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
echo "SERVER_IP : " $SERVER_IP
echo "SERVER_HTTP_PORT : " $SERVER_PORT
echo "MFPF_ADMIN_USERNAME : " $MFPF_ADMIN_USERNAME
echo "MFPF_ADMIN_PASSWORD : XXXXXX" 
echo "SERVER_ADMIN_ROOT : " $MFPF_ADMIN_ROOT
echo "CERT_PATH : " $CERT_PATH

serverURL="https://$SERVER_IP:$SERVER_PORT" 

if [ -z $CERT_PATH ]
then
        curl_cmd="curl -k";
else
        curl_cmd="curl --cacert $CERT_PATH";
fi

cd ../usr/projects
projects=$(find . -mindepth 1 -maxdepth 1 -type d)
echo "projects are $projects"
for DIR in $projects
do
	echo "Project : $DIR"
	cd $DIR
	pwd
	runtimeName=${PWD##*/} 
	echo "runtimeName is $runtimeName"
	cd bin
	for file in *-all.wlapp
	do
		# do something on "$file"
                echo " $curl_cmd -u $MFPF_ADMIN_USERNAME:$MFPF_ADMIN_PASSWORD -i -H "Accept: application/json" -F "data=@$file" -X POST $serverURL/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/$runtimeName/applications?async=false"
 		$curl_cmd -u $MFPF_ADMIN_USERNAME:$MFPF_ADMIN_PASSWORD -i -H "Accept: application/json" -F "data=@$file" -X POST $serverURL/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/$runtimeName/applications?async=false   
	done
	for file in *.adapter
	do
 		# do something on "$file"
		echo " $curl_cmd -u $MFPF_ADMIN_USERNAME:$MFPF_ADMIN_PASSWORD -i -H "Accept: application/json" -F "data=@$file" -X POST $serverURL/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/$runtimeName/adapters?async=false"

 		$curl_cmd -u $MFPF_ADMIN_USERNAME:$MFPF_ADMIN_PASSWORD -i -H "Accept: application/json" -F "data=@$file" -X POST $serverURL/$MFPF_ADMIN_ROOT/management-apis/1.0/runtimes/$runtimeName/adapters?async=false
	done	
	cd ../..
done

