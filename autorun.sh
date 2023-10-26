#!/bin/bash 

echo "Setup ELK-stack enter 1"
echo "Print system info enter 2"
echo "Start ELK-stack enter 3"
echo "Delete ELK-stack enter 4"
read user_input

function get_info {
	cd elk-server/
	elastic_pass=$(grep "ELASTIC_PASSWORD=" .env | awk -F "'" '{print $2}')
	kibana_pass=$(grep "KIBANA_SYSTEM_PASSWORD=" .env | awk -F "'" '{print $2}')
	logstash_pass=$(grep "LOGSTASH_INTERNAL_PASSWORD=" .env | awk -F "'" '{print $2}')
	echo "You all IP address:"
	ip addr show | grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | awk '{print $2}'
	echo
	echo "Elasticsearch run at http://0.0.0.0:9200"
	echo "Elasticsearch credentials:"
	echo "elastic:"$elastic_pass
	echo
	echo "Kibana run at http://0.0.0.0:5601"
	echo "Kibana credentials:"
	echo "kibana:"$kibana_pass
	echo
	echo "Logstash for beats input run at 0.0.0.0:5044"
	echo "Logstash credential:"
	echo "logstash:"$logstash_pass
}

if [ $user_input == "1" ]; then
# Add Docker's official GPG key:
	sudo apt-get update
	sudo apt-get install ca-certificates curl gnupg git -y
	sudo install -m 0755 -d /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
	echo \
  	"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  	"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  	sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	sudo apt-get update
	sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose -y

	rm -R elk-server/
	git clone https://github.com/p0h3k/elk-server
	cd elk-server/
	
	sudo docker-compose up setup

	sudo docker-compose up -d kibana logstash elasticsearch
	
	get_info

elif [ $user_input == "2" ];then
	get_info
elif [ $user_input == "3" ];then
	cd elk-server/
	sudo docker-compose up -d kibana logstash elasticsearch
elif [ $user_input == "4" ]; then
	cd elk-server/
	sudo docker-compose down

else
	echo "Command not found"
fi
