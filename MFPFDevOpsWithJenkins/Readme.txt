DevOps for MobileFirst Platform using Jenkins
=============================================

The Zip files contains the folders and files used to automate the build of MFPF project, build of MFPF container image and 
running the container in Bluemix. User should already have downloaded the MFPF Container Image before using the Jenkins for
DevOps. The zip contains following folders and files:

1)Configs
	-Contains the Jenkins Job/Project for automation of MFPF project build, Db creation, Container image build, deploy artifacts..etc.
2) Jenkins-common-scripts
	- all the common scripts used by the mfpf server and mfpf analytics
3) jenkins-dependencis
	- the libraries/jars used by the jenkins jobs for buid and deployment automation
	- there is a jar called containerRESTCall.jar, that is the java client for the ICE rest api, that is built as part of UCD and need to be copied here
4) mfpf-analytics
	- the folder jenkinsscript contains the scripts used by the jenkins job for build and deployment automation of anlatytics container images
5) mfpf-server
	- the folder jenkinsscript container the script used by jenkins job for build and deployment automation of mfpf server container images

Customer will need to unzip the attached zip to the root folder of their container images, for ex : if the container image is
availble under the folder /opt/MFPF, then you need to unzip it to the same folder. Once this is unzipped you will see that the
folders (1), (2) & (3) appears in the root folder of the container along with mfpf-libs, mfpf-anlatics & mfpf-server folders. 
You will also notice that under mfpf-analytics and mfpf-server folder, a new folder called jenkinscrips appears, that is used
by Jenkins for build and deployment automation

The config files under the Configs folder can be used for creating jobs. You should be able to use the rest api of your jenkins 
installtion to create a Job. Click on the REST API link from your Jenkins main page and read on "create job" section on how to 
use the rest api to create a new job with existing configuration

