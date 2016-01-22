#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2013. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash
checkContainerStatusWithWait()
{
	
	echo "initial java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer getCtrStateWithName $1 $2 $3 $4"
	state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
	if  [[ $state == "404" ]]  ; then
		echo "Container is not available - Quitting!"
		exit
	fi
	
	if [[ "$5" == "ipAction" ]] ; then
		echo "state just below the ip action check - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
			echo "in ip action java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer getCtrStateWithName $1 $2 $3 $4"
	        state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)

		echo "State : " $state

			if [[ "$state" == "Running" ]]; then
				echo "state is $state - will exit"
				exitVal=0
			fi		
			if  [[ $state == "NotAvailable" ]]  ; then
				echo "Container is not available - Quitting!"
			fi		
			echo "$state in while is $state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
		done
	fi
	
	if [[ "$5" == "stopAction" ]] ; then
		echo "state just below the stop action - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
			echo "in stop action java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer getCtrStateWithName $1 $2 $3 $4"
	        state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
			if [[ "$state" == "Stopped" || "$state" == "Crashed" || "$state" == "Shutdown" ]]; then
				echo "state is $state - will exit"
				exitVal=0
			fi	
			if  [[ $state == "NotAvailable" ]]  ; then
				echo "Container is not available - Quitting!"
			fi			
					
			echo "$state in while is $state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
		done
	fi
	
	if [[ "$5" == "removeAction" ]] ; then
		echo "state just below the remove action - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
			echo "in remove action java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer getCtrStateWithName $1 $2 $3 $4"
	        state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
	        if [[ "$state" == "Crashed" ]]; then
				echo "state is $state - will exit"
				removalResponse=$(java com.ibm.mfpf.container.ManageMFPServerContainer 'removeContainer' "$3" $access_token $spaceGUID $ctrId)
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
			echo "state in while is $state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
	
		done
	fi
}

getCtrState()
{
	echo "inputs to get container status is $1 $2 $3 $4"
	state=$(java com.ibm.mfpf.container.ManageMFPServerContainer 'getCtrStateWithName' $1 $2 $3 $4)
	echo "state in getCtrState is $state"
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
}

getCtrGrpState()
{
	echo "inputs to get container group status is $1 $2 $3 $4"
	state=$(java com.ibm.mfpf.container.ManageMFPServerContainer 'getCtrGrpStateWithName' $1 $2 $3 $4)
	echo "state in getCtrState is $state"
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
}

checkContainerGrpStatusWithWait()
{
	echo "initial java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer 'getCtrGrpStateWithName' $1 $2 $3 $4"
	state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrGrpStateWithName" $1 $2 $3 $4)
	echo "state in the initial java is $state"
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
	if  [[ $state == "NotAvailable" ]]  ; then
		echo "Container is not available - Quitting!"
	fi
	
	if [[ "$5" == "removeAction" ]] ; then
		echo "state just below the remove action - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
			echo "in remove action java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer 'getCtrGrpStateWithName' $1 $2 $3 $4"
	        state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrGrpStateWithName" $1 $2 $3 $4)
	        echo "state in the remove action is $state"
			if [[ "$state" == 404* ]]; then
				echo "state is not $state - will exit"
				exitVal=0
			fi			
			echo "state in while is $state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
	
		done
	fi
	
	if [[ "$5" == "createAction" ]] ; then
		echo "state just below the remove action - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
			echo "in remove action java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer 'getCtrGrpStateWithName' $1 $2 $3 $4"
	        state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrGrpStateWithName" $1 $2 $3 $4)
			if [[ "$state" == "CREATE_COMPLETE" ]]; then
				echo "state is create complete.  Will break the state check"
				exitVal=0
			fi			
			echo "state in while is $state - will sleep"
			# Allow to container group to come up with that state
	        sleep 40s
	
		done
	fi
}

