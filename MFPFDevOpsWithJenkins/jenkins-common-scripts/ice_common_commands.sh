#   Licensed Materials - Property of IBM
#   5725-I43 (C) Copyright IBM Corp. 2011, 2015. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

   
#!/usr/bin/bash
checkContainerStatusWithWait()
{
	
	echo "initial java command in method is - java com.ibm.mobilefirst.container.ManageMFPServerContainer getCtrStateWithName $1 $2 $3 $4"
	state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
	if  [[ $state == "404" ]]  ; then
		echo "Container is not available - Quitting!"
		exit
	fi
	
	if [[ "$5" == "ipAction" ]] ; then
		exitVal=1
		while [ $exitVal == 1 ]
		do
	        state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)

		echo "State : " $state

			if [[ "$state" == "Running" ]]; then
				echo "In $state state - will exit"
				exitVal=0
			fi		
			if  [[ $state == "NotAvailable" ]]  ; then
				echo "Container is not available - Quitting!"
			fi		
			echo "In $state state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
		done
	fi
	
	if [[ "$5" == "stopAction" ]] ; then
		exitVal=1
		while [ $exitVal == 1 ]
		do
	        state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
			if [[ "$state" == "Stopped" || "$state" == "Crashed" || "$state" == "Shutdown" ]]; then
				echo "In $state state - will exit"
				exitVal=0
			fi	
			if  [[ $state == "NotAvailable" ]]  ; then
				echo "Container is not available - Quitting!"
			fi			
					
			echo "In $state state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
		done
	fi
	
	if [[ "$5" == "removeAction" ]] ; then
		exitVal=1
		while [ $exitVal == 1 ]
		do
	        state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
	        if [[ "$state" == "Crashed" ]]; then
				echo "In $state state - will exit"
				removalResponse=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer 'removeContainer' "$3" $access_token $spaceGUID $ctrId)
				if  [[ $removalResponse == Error* ]]  ; then
					echo "Error Occured in removal of container - Quitting!"
			 		exit 1
				elif [[ "$removalResponse" == "204" ]] ; then
					echo "Request for removal of container succeeded"
				fi
			fi	
			if  [[ $state == "NotAvailable" ]]  ; then
				echo "Container is not available - Quitting!"
				exitVal=0
			fi	
			echo "In $state state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
	
		done
	fi
}

getCtrState()
{
	state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer 'getCtrStateWithName' $1 $2 $3 $4)
	echo "Contatiner in $state state"
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
}

getCtrGrpState()
{
	state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer 'getCtrGrpStateWithName' $1 $2 $3 $4)
	echo "Container in $state state"
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
}

checkContainerGrpStatusWithWait()
{
	state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getCtrGrpStateWithName" $1 $2 $3 $4)
	echo "Container group in $state state"
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
	if  [[ $state == "NotAvailable" ]]  ; then
		echo "Container is not available - Quitting!"
	fi
	
	if [[ "$5" == "removeAction" ]] ; then
		echo "Container state before the remove action - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
	        state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getCtrGrpStateWithName" $1 $2 $3 $4)
	        echo "state in the remove action is $state"
			if [[ "$state" == 404* ]]; then
				echo "state is not $state - will exit"
				exitVal=0
			fi			
			echo "Container in $state state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
	
		done
	fi
	
	if [[ "$5" == "createAction" ]] ; then
		echo "Container state before the create action - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
	        state=$(java com.ibm.mobilefirst.container.ManageMFPServerContainer "getCtrGrpStateWithName" $1 $2 $3 $4)
			if [[ "$state" == "CREATE_COMPLETE" ]]; then
				echo "state is create complete.  Will break the state check"
				exitVal=0
			fi			
			echo "In $state state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
	
		done
	fi
}

