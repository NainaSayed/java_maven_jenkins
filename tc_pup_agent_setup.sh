#!/bin/bash
#
# This script does the following
#
#    * Create AWS resources like EC2 instance, Security Group and a Key pair for Tomcat App Server
#    * Install Puppet Agent package on the newly created Tomcat EC2 instance
#    * Configure /etc/puppet/puppet.conf for the Tomcat Puppet Agent
#    * Generate certificate signing request to Puppet Master
#    * Puppet Master to sign the CSR generated and add Tomcat server as a puppet agent

# FETCHING TOMCAT AND PUPPET MASTER SERVER DNS and IP's

printf "\n\n##########FETCHING TOMCAT AND PUPPET MASTER SERVER DNS and IP's\n"
TC_SERVER_PRI_DNS=`sed -n '1p' < tc_pri_dns.txt`
echo "TOMCAT SERVER PRIVATE DNS: $TC_SERVER_PRI_DNS"
TC_SERVER_PUB_DNS=`sed -n '1p' < tc_pub_dns.txt`
echo "TOMCAT SERVER PUBLIC DNS: $TC_SERVER_PUB_DNS"
TC_SERVER_PRI_IP=`sed -n '1p' < tc_pri_ip.txt`
echo "TOMCAT SERVER PRIVATE IP: $TC_SERVER_PRI_IP"
PUPMASTER_PRI_IP=`sed -n '1p' < pup_master_pri_ip.txt`
echo "PUPPET MASTER PRIVATE IP: $PUPMASTER_PRI_IP"
PUPMASTER_PRI_DNS=`sed -n '1p' < pup_master_pri_dns.txt`
echo "PUPPET MASTER PRIVATE DNS: $PUPMASTER_PRI_DNS"

printf "\n\n###########SSH TO TOMCAT EC2 INSTANCE AND INSTALL PUPPET AGENT\n"
sleep 25
SSH_MSG_1=$(ssh -tt ubuntu@$TC_SERVER_PRI_DNS -i "tomcat_ec2_key" -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c 'hostname tomcatpuppetagent.ec2.internal; \
	echo tomcatpuppetagent.ec2.internal > /etc/hostname; \
	echo $PUPMASTER_PRI_IP puppetmaster.ec2.internal ${PUPMASTER_PRI_DNS} >> /etc/hosts; \
	echo ${TC_SERVER_PRI_IP} tomcatpuppetagent.ec2.internal ${TC_SERVER_PRI_DNS} >> /etc/hosts; \
	wget https://apt.puppetlabs.com/puppet5-release-bionic.deb; \
	dpkg -i puppet5-release-bionic.deb; \
	apt-get update -y; \
	apt-get install puppet -y; \
	exit;'")
echo $SSH_MSG_1
export EXIT_CODE=$?
export ERR_MSG="Error: ""$SSH_MSG_1"
test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

printf "\n\n###########CONFIGURING PUPPET AGENT ON TOMCAT EC2 INSTANCE\n"
ssh_cmd="$(cat <<-EOF
    ls /home/ubuntu;

    if [ -e /etc/puppet/puppet.conf ]; then
        echo "Conf file is /etc/puppet/puppet.conf"
        mv /etc/puppet/puppet.conf /etc/puppet/puppet.conf.orig
        echo [agent] > /etc/puppet/puppet.conf
        echo certname = tomcatpuppetagent.ec2.internal >> /etc/puppet/puppet.conf
        echo server = puppetmaster.ec2.internal >> /etc/puppet/puppet.conf
        echo environment = production >> /etc/puppet/puppet.conf
        systemctl restart puppet
        systemctl enable puppet
    else
        echo "Conf file is /etc/puppetlabs/puppet/puppet.conf"
        mv /etc/puppetlabs/puppet/puppet.conf /etc/puppetlabs/puppet/puppet.conf.orig
        echo [agent] > /etc/puppetlabs/puppet/puppet.conf
        echo certname = tomcatpuppetagent.ec2.internal >> /etc/puppetlabs/puppet/puppet.conf
        echo server = puppetmaster.ec2.internal >> /etc/puppetlabs/puppet/puppet.conf
        echo environment = production >> /etc/puppetlabs/puppet/puppet.conf
        systemctl restart puppet
        systemctl enable puppet
    fi
EOF
)"


ssh -tt ubuntu@$TC_SERVER_PRI_DNS -i tomcat_ec2_key -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c '$ssh_cmd'"

echo $ssh_cmd
export EXIT_CODE=$?
export ERR_MSG="Error: ""$ssh_cmd"
test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

printf "\n\n############SIGNING PUPPET CERTS FROM PUPPET MASTER FOR NEWLY CREATED TOMCAT PUPPET AGENT\n"
sleep 20
SSH_MSG_3=$(ssh -i /opt/pup_setup_tf/puppet_ec2_key -tt ubuntu@$PUPMASTER_PRI_IP -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c 'echo ${TC_SERVER_PRI_IP} tomcatpuppetagent.ec2.internal ${TC_SERVER_PRI_DNS} >> /etc/hosts; \
        puppet cert list; \
	puppet cert sign tomcatpuppetagent.ec2.internal; \
	exit;'")
echo $SSH_MSG_3
export EXIT_CODE=$?
export ERR_MSG="Error: ""$SSH_MSG_3"
test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

#printf "\n\n############TEST TOMCAT PUPPET AGENT CONNECTION TO PUPPET MASTER AND APPLY CATALOG\n"
#SSH_MSG_4=$(ssh -i tomcat_ec2_key -tt ubuntu@$TC_SERVER_PRI_DNS -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c 'puppet agent --test; \
#	sleep 25; \
#	exit;'")
#echo $SSH_MSG_4
#export EXIT_CODE=$?
#export ERR_MSG="Error: ""$SSH_MSG_4"
#test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

printf "\n\n############INSTALLING JAVA PUPPET MODULE ON PUPPET MASTER- PREREQUISITE FOR RUNNING TOMCAT\n"
SSH_MSG_5=$(ssh -i /opt/pup_setup_tf/puppet_ec2_key -tt ubuntu@$PUPMASTER_PRI_IP -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c 'puppet module install puppetlabs-java --version 5.0.1 --modulepath=/etc/puppet/code/environments/production/modules; \
	cp /etc/puppet/code/environments/production/modules/java/examples/init.pp /etc/puppet/code/environments/production/manifests/java.pp; \
	exit;'")
echo $SSH_MSG_5
export EXIT_CODE=$?
export ERR_MSG="Error: ""$SSH_MSG_5"
test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

printf "\n\n############COPYING THE PROJECT ARTIFACTS (.war) TO PUPPET MASTER\n"
scp -i /opt/pup_setup_tf/puppet_ec2_key ${WORKSPACE}/target/*.war ubuntu@$PUPMASTER_PRI_IP:/tmp
if [ $? -eq 0 ]; then
	printf "\n Successfully copied\n";
fi


printf "\n\n############INSTALLING PUPPET TOMCAT MODULE AND DEPENDENCIES ON PUPPET MASTER\n"
SSH_MSG_6=$(ssh -i /opt/pup_setup_tf/puppet_ec2_key -tt ubuntu@$PUPMASTER_PRI_IP -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c 'puppet module install puppetlabs-stdlib --modulepath=/etc/puppet/code/environments/production/modules; \
	puppet module install puppetlabs-tomcat --modulepath=/etc/puppet/code/environments/production/modules; \
	mkdir -p /etc/puppet/code/environments/production/modules/tomcat/files; \
	cp /tmp/mvn-hello-world.war /etc/puppet/code/environments/production/modules/tomcat/files; \
	exit;'")
echo $SSH_MSG_6
export EXIT_CODE=$?
export ERR_MSG="Error: ""$SSH_MSG_6"
test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

printf "\n\n############COPYING THE PUPPET MANIFESTS FOR TOMCAT TO PUPPET MASTER\n"
scp -i /opt/pup_setup_tf/puppet_ec2_key ${WORKSPACE}/tomcat.pp ubuntu@$PUPMASTER_PRI_IP:/tmp
if [ $? -eq 0 ]; then
        printf "\n Successfully copied\n";
fi

SSH_MSG_7=$(ssh -i /opt/pup_setup_tf/puppet_ec2_key -tt ubuntu@$PUPMASTER_PRI_IP -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c 'cp /tmp/tomcat.pp /etc/puppet/code/environments/production/manifests; \
	exit;'")
echo $SSH_MSG_7
export EXIT_CODE=$?
export ERR_MSG="Error: ""$SSH_MSG_7"
test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

printf "\n\n###########DEPLOYING WAR TO TOMCAT APP SERVER USING PUPPET MANIFESTS; APPLYING MASTER CATALOG\n"
SSH_MSG_8=$(ssh -i tomcat_ec2_key -tt ubuntu@$TC_SERVER_PRI_DNS -oStrictHostKeyChecking=no "/usr/bin/sudo bash -c 'puppet agent --test; \
	exit;'")
echo $SSH_MSG_8

export EXIT_CODE=$?
export ERR_MSG="Error: ""$SSH_MSG_8"
test $EXIT_CODE -ne 0 && $EXIT_CODE $ERR_MSG exit

printf "\n\n##### DEPLOYMENT WAS SUCCESSFUL \n"

printf "\n\n########## PLEASE ACCESS THE APPLICATION USING BELOW URL\n"
printf "\n\nhttp://${TC_SERVER_PUB_DNS}:8080/mvn-hello-world\n"
