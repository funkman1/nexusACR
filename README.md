# Sonotype Nexus 3 Docker Proxy Configuration with Azure Container Registry


## Overview

This project aims to produce the necessary components needed to create a Docker Proxy repository that will cache images pulled from an external Azure Container registry.

## Features

- Create an Azure virtual machine to act as our Nexus server.
- Nexus service configuration on our newly created virtual machine.
- Create an Azure Container Registry.
- Connect our ACR with our Nexus repository using proper authentication methods.


## Creating an Azure VM to host Nexus 

To use Nexus, we need somewhere to host it. I chose to host the service on an Azure VM just to start with a clean slate, but you can host the service locally on your machine if need be.

### To configure an Azure VM do the following:

1. Sign in to the Azure portal and search for virtual machines.
2. Click Create in the top left corner
3. On the Basics screen, make sure to choose the appropriate subscription and resource group that your VM will be associated with. You can also create a new resource group on this page.
4. Assign a unique name to your virtual machine
5. Select the appropriate Region/AZ that best aligns with your location.
6.	Select the image of your VM, I chose Ubuntu server 22.04 

    a.	If you want to select a different image, select see all images and browse for your desired image
7.	Select a size for the VM, refer to the Nexus repo recommendations profile below
    
    a.	https://help.sonatype.com/en/sonatype-nexus-repository-system-requirements.html

    b.	**I chose B4ms 4 CPU and 16GiB (need min 4 CPU)**

8. Authentication options(can choose either, SSH recommended)

    a.	Ssh public key
    
    b.	Password

9.	Under inbound port rules, allow default selected ports of SSH(22)
10. Move on to the disks page, leave the disk size as image default, and for disk type, I chose standard SSD.
11. Onto the networking page, you must choose a virtual network and subnet, I used the default inputs here as I created a resource group.
12. Enable delete public IP and NIC when VM is deleted for nicer cleanup.
13. For the management, monitoring, and advanced sections, feel free to review some of the configuration here but I left everything as default.
14. Review the VM configuration on the review + create screen and if everything looks correct, hit create.



## Nexus Setup

1.	To run  Nexus on our newly created Linux VM, these are the outlined steps

    a.	Install jdk, wget, and other necessary tools

    b.	Download the Nexus tar file & untar the file

    c.	Set up Nexus user

    d.	Start Nexus and access from your web browser
2. After we SSH into our VM, the first step is to make sure our machine packages are up to date.

    a.	Run the command **sudo apt update -y** to retrieve packages that need to be updated

    b.	Run the command **sudo apt upgrade -y** to download the updates previously retrieved

Note: You might have to use yum instead of apt as the package manager depends on the OS type

3.	Next, we should install wget so that we can download the tar file from the download site

    a.	Run the command **sudo apt install wget -y**

4.	Download and verify Java installation

    a.	Start by running the command **java version** to display the current version of java installed on the machine.

    b.	If java has not been installed yet, there will be a list of commands provided that will offer ways to download java, I chose to use the command **sudo apt install default-jre.**

    c. Verify the java installation by running the command **java -version**
5.	Now lets create a directory where we can download the tar file 

    a.	Run the command **sudo mkdir /app**, and then **cd app**, and **pwd** to verify you are in the /app directory.
6.	Retrieve the tar download file

    a.	Go the to following link https://help.sonatype.com/en/download.html and copy the download URL for the OS and java version you are using.

    b.	Run the command **sudo wget *CopiedURL***,  to download the tar file

    c.	Run the **ls** command to verify the tar file is in the directory

    d.	Run the command **sudo tar -xvf *filename***  to untar the file

    e.	Run the **ls** command and you should see 2 files, sonatype-work and nexus-version

    f.	We no longer need the tar file so we can remove it using the command **sudo rm *filename*** 

7.	Rename nexus-version file

    a.	Run the command **sudo mv nexus-version nexus**
    
    b.	The file should now show to be called nexus

8.	Add nexus user

    a.	Run the command sudo adduser nexus

    b.	Give the new user the right privileges to necessary folders, do the following:

        i.	sudo chown -R nexus:nexus /app/nexus

        ii.	sudo chown -R nexus:nexus /app/sonatype-work
9.	Add nexus user to nexus.rc file

    a.	Run **sudo vi /app/nexus/bin/nexus.rc**

    b.	**Uncomment the run_as_user line and add nexus in the “”**

    c.	Verify by running the **cat** command on the file
10.	Start the nexus service

    a.	Run the command **./nexus/bin/nexus start**

    b.	Verify nexus is running by using the command **./nexus/bin/nexus status**
11.	Add port **8081** and **8082** to reach the nexus UI from the browser

    a.	In the Azure portal, go to networking, and click create port rule, then inbound port rule

    b.	Set destination port as 8081 and protocol TCP, add a description, then hit create. Do the same for port 8082, we will need to use it later.
12.	Access the Nexus UI

    a.	You should now be able to see the Nexus UI by going to the IP associated with your machine and appending :8081, so *IP*:8081

13.	Sign in to the admin user

    a.	Click sign-in located in the top right of the UI and you will see the instructions to retrieve the admin user password

    i.	Use the command **cat /app/sonatype-work/nexus3/admin.password**

    ii.	Copy the password displayed and log in using that and admin as the user

    iii.	You will then be prompted to configure a new password

    iv.	Disable anonymous access
14.	Make sure to check the status checks provided in UI to see if your host is sufficient to run Nexus
    
    a.	Under the support tab, then status, view to see if there are any warnings.
## Create an Azure Container Registry
1.  This process is pretty straightforward and can be done from the Azure portal.

2. Log in to the Azure portal and search for container registries.
3. Fill out the required fields with the appropriate subscription and resource group, followed by a unique name for the registry.
4. Choose the pricing plan with the necessary capabilites you need, I chose basic.
5. Finally, hit review + create to finish.

## Creating a Service principle to interact with our ACR and Nexus
1. To avoid the insecurities revolving around using an admin user to authenticate to our ACR and Nexus repo, we will need to create a service principal. 

    Note: An Azure service principal is an identity that allows access to Azure resources for automated tools, hosted services, and applications.  

2. Run the acrsp.sh script to create the service principle. **(Make sure to edit the ACR_NAME and SERVICE_PRINCIPAL_NAME variables in the script before running it)**
    
    The script will create a service principle with the role of acrpull, this is because we are only using Nexus to pull from our ACR, we don't want to give the ability to push new images.
    
    The service principal ID and password will be displayed when the script is complete, **make sure to store these credentials somewhere safe like Azure key vault.**

   **Note: These credentials are only good for 1 year before you must create another service principal.**

## Configure a Docker Proxy in Nexus
1. After signing into our admin Nexus user, on the left sidebar panel of the Nexus UI, click security and then realms.

2. Change the docker bearer token from available to active.
3. Once you have done that click the cog icon at the top left of the screen, then click repositories.
4. Click Create Repository, and then click docker (proxy).
5. Give your repo a unique name 
6. Click the check box for HTTP and type in port 8082 that we opened for this earlier.
7. Click the check box to allow anonymous docker pull, this is why we enabled the docker bearer pull token.
8. Type your login server for your ACR with https:// in the remote storage URL space and click use certs stored in Nexus box.
9. Click view certificate and add the certificate to truststore.
10. Select a blob store that will hold our cache images, if you don't have a blob store created yet, go to blob stores, and create a file or S3 store.
11. Lastly, click authentication for HTTP at the bottom of the form and type the Service Principal ID and password we configured from earlier here.
12. I left everything else as default.

## Test our Nexus Proxy with ACR

1. To connect to our ACR we first need to make sure we have docker installed and running.

    a.	Use the command **docker version** to verify docker is installed

    b.	Use the command **sudo systemctl status docker** to ensure that the service is running
2. Login using service principal credentials
    
    a. To login use the following command, **docker login *loginservername* -u *serviceprincipleid* -p *serviceprincipalpassword*** 
   
    b.	if you receive an error described as “/var/run/docker.sock: connect: permission denied” while trying to connect, run the command **sudo chmod 666 /var/run/docker.sock** and try again
3. One last important step to configure before we try to pull from ACR, use the command **sudo vi /etc/docker/daemon.json**  and add the following text:
        
        {
            "insecure-registries": [
                "YOUR-VM-HOSTNAME:8082"
            ]

        }

4. run the command **sudo systemctl restart docker** to restart the docker service with our recent change.
5. Now we can try to pull an image from our ACR by running the command,

   **docker pull nexus-hostname:repository-port/image**
6. To confirm that the pull request was successful you should see the image folder in the browse repo section in Nexus UI and a repo status of Remote available.

## Debug Methods
1. Enable debug for more in depth docker logs
    
    a. To enable debug level logs you can run the command **sudo vi /etc/docker/daemon.json** and add the line.
        
        "debug": true 
2. If you **cd into /var/log**, running the command **tail syslog** can also prove to be useful to see the most recent events.