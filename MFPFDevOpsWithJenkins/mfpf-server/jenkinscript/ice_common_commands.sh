#   Licensed Materials - Property of IBM 
#   5725-I43 (C) Copyright IBM Corp. 2011, 2013. All Rights Reserved.
#   US Government Users Restricted Rights - Use, duplication or
#   disclosure restricted by GSA ADP Schedule Contract with IBM Corp.  
   
#!/usr/bin/bash
echo "in ice commands - just including"
checkContainerStatusWithWait()
{
	echo "in container mthod $1"
	echo "in container mthod $2"
	echo "in container mthod $3"
	echo "in container mthod $4"
	echo "in container mthod $5"
	
	echo "initial java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer getCtrStateWithName $1 $2 $3 $4"
	state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
	if  [[ $state == NotAvailable ]]  ; then
		echo "Container is not availabe - Quitting!"
		break
	fi
	
	if [[ "$5" == "ipAction" ]] ; then
		echo "state just below the ip action check - $state"
		exitVal=1
		while [ $exitVal == 1 ]
		do
			echo "in ip action java command in method is - java com.ibm.mfpf.container.ManageMFPServerContainer getCtrStateWithName $1 $2 $3 $4"
	        state=$(java com.ibm.mfpf.container.ManageMFPServerContainer "getCtrStateWithName" $1 $2 $3 $4)
			if [[ "$state" == "Running" ]]; then
				echo "state is $state - will exit"
				exitVal=0
				break
			fi		
			if [[ "$state" == "NotAvailable" ]]; then
				echo "state is $state - container might have crashed.  Quitting!"
				exit 1
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
				break
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
			if [[ "$state" == "NotAvailable" ]]; then
				echo "state is not available - will exit"
				exitVal=0
				break
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
	echo "inputs to get container status is $1 $2 $3 $4"
	state=$(java com.ibm.mfpf.container.ManageMFPServerContainer 'getCtrGrpStateWithName' $1 $2 $3 $4)
	echo "state in getCtrState is $state"
	if  [[ $state == Error* ]]  ; then
		echo "Error Occured in state retrieval - Quitting!"
		exit 1
	fi
	
	
}


