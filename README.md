# Sonotype Nexus 3 Docker Proxy Configuration with Azure Container Registry


## Overview

This project aims to produce the necessary components needed to create a Docker Proxy repository that will cache images pulled from an external Azure Container registry.

## Features

- Create an Azure virtual machine to act as our Nexus server.
- Nexus service configuration on our newly created virtual machine.
- Create an Azure Container Registry.
- Connect our ACR with our Nexus repository using proper authentication methods.

## Important Notes

   **Service Principal credentials are only good for 1 year before you must create another service principal.**

   **If you already have Nexus running and have an ACR, skip to section 4.**


## 1) Creating an Azure VM to host Nexus 

To use Nexus, we need somewhere to host it. I chose to host the service on an Azure VM just to start with a clean slate, but you can host the service locally on your machine if need be.

### To configure an Azure VM do the following:

&nbsp;&nbsp;&nbsp;**1.1)** Sign in to the Azure portal and search for virtual machines.

&nbsp;&nbsp;&nbsp;**1.2)** Click Create in the top left corner

&nbsp;&nbsp;&nbsp;**1.3)** On the Basics screen, make sure to choose the appropriate subscription and resource group that your VM will be associated with.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;You can also create a new resource group on this page.

&nbsp;&nbsp;&nbsp;**1.4)** Assign a unique name to your virtual machine

&nbsp;&nbsp;&nbsp;**1.5)** Select the appropriate Region/AZ that best aligns with your location.

&nbsp;&nbsp;&nbsp;**1.6)**	Select the image of your VM, I chose Ubuntu server 22.04

&nbsp;&nbsp;&nbsp;**1.7)**	Select a size for the VM, refer to the Nexus repo recommendations profile below, **I chose B4ms 4 CPU and 16GiB (need min 4 CPU)**
    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;https://help.sonatype.com/en/sonatype-nexus-repository-system-requirements.html

&nbsp;&nbsp;&nbsp;**1.8)** Authentication options(can choose either, **SSH recommended**)

&nbsp;&nbsp;&nbsp;**1.9)**	Under inbound port rules, allow default selected ports of SSH(22)

&nbsp;&nbsp;&nbsp;**1.10)** Move on to the disks page, leave the disk size as image default, and for disk type, I chose standard SSD.

&nbsp;&nbsp;&nbsp;**1.11)** Onto the networking page, you must choose a virtual network and subnet, I used the default inputs here as I created a resource group.

&nbsp;&nbsp;&nbsp;**1.12)** Enable delete public IP and NIC when VM is deleted for nicer cleanup.

&nbsp;&nbsp;&nbsp;**1.13)** For the management, monitoring, and advanced sections, feel free to review some of the configuration here but I left everything as default.

&nbsp;&nbsp;&nbsp;**1.14)** Review the VM configuration on the review + create screen and if everything looks correct, hit create.



## 2) Nexus Setup

&nbsp;&nbsp;&nbsp;**2.1)**	To run  Nexus on our newly created Linux VM, these are the outlined steps

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Install jdk, wget, and other necessary tools

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Download the Nexus tar file & untar the file

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Set up Nexus user

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Start Nexus and access from your web browser

&nbsp;&nbsp;&nbsp;**2.2)** After we SSH into our VM, the first step is to make sure our machine packages are up to date. Run the following commands:

&nbsp;&nbsp;&nbsp;```sudo apt update -y```

&nbsp;&nbsp;&nbsp;```sudo apt upgrade -y```

&nbsp;&nbsp;&nbsp;Note: You might have to use a different package manager depending on your OS type

&nbsp;&nbsp;&nbsp;**2.3)**	Next, we should install wget so that we can download the tar file from the download site, run the following command:

&nbsp;&nbsp;&nbsp;```sudo apt install wget -y```

&nbsp;&nbsp;&nbsp;**2.4)**	Download and verify Java installation

&nbsp;&nbsp;&nbsp;Start by running the command 
   ``` java version ```
to display the current version of java installed on the machine.

&nbsp;&nbsp;&nbsp;If java has not been installed yet, there will be a list of commands provided that will offer ways to download java, I chose to use the command 

&nbsp;&nbsp;&nbsp;```sudo apt install default-jre```

&nbsp;&nbsp;&nbsp;Verify the java installation by running the command ```java -version```

&nbsp;&nbsp;&nbsp;**2.5)**	Now lets create a directory where we can download the tar file 

&nbsp;&nbsp;&nbsp;Run the command ```sudo mkdir /app```, and then ```cd app```, and ```pwd``` to verify you are in the /app directory.

&nbsp;&nbsp;&nbsp;**2.6)**	Retrieve the tar download file

&nbsp;&nbsp;&nbsp;Go the to following link https://help.sonatype.com/en/download.html and copy the download URL for the OS and java version you are using.

&nbsp;&nbsp;&nbsp;Run the command ```sudo wget CopiedURL```,  to download the tar file

&nbsp;&nbsp;&nbsp;Run the ```ls``` command to verify the tar file is in the directory

&nbsp;&nbsp;&nbsp;Run the command ```sudo tar -xvf tarfilename```  to untar the file

&nbsp;&nbsp;&nbsp;Run the ```ls``` command and you should see 2 files, sonatype-work and nexus-version

&nbsp;&nbsp;&nbsp;We no longer need the tar file so we can remove it using the command ```sudo rm tarfilename``` 

&nbsp;&nbsp;&nbsp;**2.7)**	Rename nexus-version file

&nbsp;&nbsp;&nbsp;Run the command ```sudo mv nexus-version nexus```
    
&nbsp;&nbsp;&nbsp;The file should now show to be called nexus

&nbsp;&nbsp;&nbsp;**2.8)**	Add nexus user

&nbsp;&nbsp;&nbsp;Run the command ```sudo adduser nexus```

&nbsp;&nbsp;&nbsp;Give the new user the right privileges to necessary folders, do the following:

&nbsp;&nbsp;&nbsp;```sudo chown -R nexus:nexus /app/nexus```

&nbsp;&nbsp;&nbsp;```sudo chown -R nexus:nexus /app/sonatype-work```

&nbsp;&nbsp;&nbsp;**2.9)**	Add nexus user to nexus.rc file

&nbsp;&nbsp;&nbsp;Run ```sudo vi /app/nexus/bin/nexus.rc```

&nbsp;&nbsp;&nbsp;**Uncomment the run_as_user line and add nexus in the “”**

&nbsp;&nbsp;&nbsp;Verify by running the ```cat``` command on the file

&nbsp;&nbsp;&nbsp;**2.10)**	Start the nexus service

&nbsp;&nbsp;&nbsp;Run the command ```./nexus/bin/nexus start```

&nbsp;&nbsp;&nbsp;Verify nexus is running by using the command ```./nexus/bin/nexus status```

&nbsp;&nbsp;&nbsp;**2.11)**	Add port **8081** and **8082** to reach the nexus UI from the browser

&nbsp;&nbsp;&nbsp;In the Azure portal, go to networking, and click create port rule, then inbound port rule

&nbsp;&nbsp;&nbsp;Set destination port as 8081 and protocol TCP, add a description, then hit create. Do the same for port 8082, we will need to use it later.

&nbsp;&nbsp;&nbsp;**2.12)**	Access the Nexus UI

&nbsp;&nbsp;&nbsp;You should now be able to see the Nexus UI by going to the IP associated with your machine and appending :8081, so *IP*:8081

&nbsp;&nbsp;&nbsp;**2.13)**	Sign in to the admin user

&nbsp;&nbsp;&nbsp;Click sign-in located in the top right of the UI and you will see the instructions to retrieve the admin user password

&nbsp;&nbsp;&nbsp;Use the command ```cat /app/sonatype-work/nexus3/admin.password```

&nbsp;&nbsp;&nbsp;Copy the password displayed and log in using that and admin as the user

&nbsp;&nbsp;&nbsp;You will then be prompted to configure a new password

&nbsp;&nbsp;&nbsp;Disable anonymous access

&nbsp;&nbsp;&nbsp;**2.14)**	Make sure to check the status checks provided in UI to see if your host is sufficient to run Nexus
    
&nbsp;&nbsp;&nbsp;Under the support tab, then status, view to see if there are any warnings.
## 3) Create an Azure Container Registry
&nbsp;&nbsp;&nbsp;**3.1)** This process is pretty straightforward and can be done from the Azure portal.

&nbsp;&nbsp;&nbsp;**3.2)** Log in to the Azure portal and search for container registries.

&nbsp;&nbsp;&nbsp;**3.3)** Fill out the required fields with the appropriate subscription and resource group, followed by a unique name for the registry.

&nbsp;&nbsp;&nbsp;**3.4)** Choose the pricing plan with the necessary capabilites you need, I chose basic.

&nbsp;&nbsp;&nbsp;**3.5)** Finally, hit review + create to finish.

## 4) Creating a Service principle to interact with our ACR and Nexus
&nbsp;&nbsp;&nbsp;**4.1)** To avoid the insecurities revolving around using an admin user to authenticate to our ACR and Nexus repo, we will need to create a service principal. 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Note: An Azure service principal is an identity that allows access to Azure resources for automated tools, hosted services, and applications.  

&nbsp;&nbsp;&nbsp;**4.2)** Run the acrsp.sh script to create the service principle. **(Make sure to edit the ACR_NAME and SERVICE_PRINCIPAL_NAME variables in the script before running it)**
    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The script will create a service principle with the role of acrpull, this is because we are only using Nexus to pull from our ACR, we don't want to give the ability to push new images.
    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The service principal ID and password will be displayed when the script is complete, **make sure to store these credentials somewhere safe like Azure key vault.**

## 5) Configure a Docker Proxy in Nexus
&nbsp;&nbsp;&nbsp;**5.1)** After signing into our admin Nexus user, on the left sidebar panel of the Nexus UI, click security and then realms.

&nbsp;&nbsp;&nbsp;**5.2)** Change the docker bearer token from available to active.

&nbsp;&nbsp;&nbsp;**5.3)** Once you have done that click the cog icon at the top left of the screen, then click repositories.

&nbsp;&nbsp;&nbsp;**5.4)** Click Create Repository, and then click docker (proxy).

&nbsp;&nbsp;&nbsp;**5.5)** Give your repo a unique name 

&nbsp;&nbsp;&nbsp;**5.6)** Click the check box for HTTP and type in port 8082 that we opened for this earlier.

&nbsp;&nbsp;&nbsp;**5.7)** Click the check box to allow anonymous docker pull, this is why we enabled the docker bearer pull token.

&nbsp;&nbsp;&nbsp;**5.8)** Type your login server for your ACR with https:// in the remote storage URL space and click use certs stored in Nexus box.

&nbsp;&nbsp;&nbsp;**5.9)** Click view certificate and add the certificate to truststore.

&nbsp;&nbsp;&nbsp;**5.10)** Select a blob store that will hold our cache images, if you don't have a blob store created yet, go to blob stores, and create a file or S3 store.

&nbsp;&nbsp;&nbsp;**5.11)** Lastly, click authentication for HTTP at the bottom of the form and type the Service Principal ID and password we configured from earlier here.

&nbsp;&nbsp;&nbsp;**5.12)** I left everything else as default.

## 6) Test our Nexus Proxy with ACR
### Push image to ACR

**Note: If you already have images in ACR to test with, skip to the next section, Pull image using Nexus. This section is needed to add images to our empty ACR we just created.**

&nbsp;&nbsp;&nbsp;**6.1)** To connect to our ACR we first need to make sure we have docker installed and running.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Use the command ```docker version``` to verify docker is installed

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Use the command ```sudo systemctl status docker``` to ensure that the service is running

&nbsp;&nbsp;&nbsp;**6.2)** Login using service principal credentials, **DO NOT USE THE ACRPULL CREDENTIAL CREATED PREVIOUSLY FOR THIS, you will need to create a new service principle with the role ARCPUSH.** Simply change the role to arcpush in the script and give the service principal a name different than the pull service principle.
    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; To login use the following command, ```docker login acrloginservername -u serviceprincipleid -p serviceprincipalpassword```

&nbsp;&nbsp;&nbsp;**6.3)** Pull down the official docker hello-world image by running the command ```docker pull hello-world```

&nbsp;&nbsp;&nbsp;**6.4)** Verify the image has been retrieved by running the command ```docker images```, it should show hello-world

&nbsp;&nbsp;&nbsp;**6.5)** To push our image to our ACR repo we first need to tag our hello-world image, run the command, ```docker tag hello-world acrloginserver /hello-world:v1```

&nbsp;&nbsp;&nbsp;**6.6)** Now we are ready to push our image to ACR by running the command, ```docker push acrloginserver/hello-world:v1```

&nbsp;&nbsp;&nbsp;**6.7)** To confirm that the image has pushed correctly, run the command, ```az acr repository list --name registryname --output table``` , it should display the following

**Note: acrloginserver and registry name are different, you can find these by going to your ACR in the azure portal, going to settings then access keys.**


### Pull image using Nexus
   
&nbsp;&nbsp;&nbsp;**6.8)** One last important step to configure before we try to pull from ACR, use the command ```sudo vi /etc/docker/daemon.json```  and add the following text: **Note: only required if you dont have SSL configured for your nexus servers**
        
        {
            "insecure-registries": [
                "YOUR-VM-HOSTNAME:8082"
            ]

        }




&nbsp;&nbsp;&nbsp;**6.9)** run the command ```sudo systemctl restart docker``` to restart the docker service with our recent change.



&nbsp;&nbsp;&nbsp;**6.10)** Now we can try to pull an image from Nexus by running the command,



&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;```docker pull nexus-hostname:repository-port/image```

&nbsp;&nbsp;&nbsp;**6.11)** To confirm that the pull request was successful you should see the image folder in the browse repo section in Nexus UI and a repo status of Remote available.


## 7) Debug Methods

### Steps to enable debug logging for outbound requests from Nexus

&nbsp;&nbsp;&nbsp;**7.1)** Log in to Nexus using the admin user

&nbsp;&nbsp;&nbsp;**7.2)** Click the cog icon and scroll down on the left side panel to the support section and click logging.

&nbsp;&nbsp;&nbsp;**7.3)** Find the Logger name called org.apache.http.wire, click on it and switch the logger level to debug, and click save.

&nbsp;&nbsp;&nbsp;**7.4)** Then go to the logs section and click on the outbound-request.log and you will be able to view the outbound requests.
