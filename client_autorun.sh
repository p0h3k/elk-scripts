version=8.10.2

sudo apt-get install wget rpm jq -y

#wget http://mirrors.aliyun.com/elasticstack/yum/elastic-8.x/$version/filebeat-$version-x86_64.rpm

sudo rpm --install --nodeps filebeat-$version-x86_64.rpm

echo "Enter Server IP: "
read client_ip

sudo sed -i 's/#host: "localhost:5601"/host: "localhost:5601"/g' /etc/filebeat/filebeat.yml
sudo sed -i 's/#username: "elastic"/username: "elastic"/g' /etc/filebeat/filebeat.yml
sudo sed -i 's/#password: "changeme"/password: "changeme"/g' /etc/filebeat/filebeat.yml


sudo sed -i "s/localhost/${client_ip}/g" /etc/filebeat/filebeat.yml


sudo apt-get install auditd -y

sudo systemctl start auditd
sudo systemctl enable auditd

sudo add-apt-repository ppa:oisf/suricata-stable

sudo apt install suricata -y 

sudo systemctl enable suricata.service


sudo sed -i 's/community-id: false/community-id: true/g' /etc/suricata/suricata.yaml

interface=$(ip -p -j route show default | jq -r '.[0].dev')

sudo sed -i "s/interface: eth0/interface: ${interface}/g" /etc/suricata/suricata.yaml

sudo echo 'detect-engine:' >> /etc/suricata/suricata.yaml
sudo echo '  - rule-reload: true' >> /etc/suricata/suricata.yaml

sudo suricata-update
sudo cp /var/lib/suricata/rules/suricata.rules /etc/suricata/
sudo suricata -T -c /etc/suricata/suricata.yaml -v


sudo systemctl start suricata.service


export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY


sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'

sudo apt-get update -y

sudo apt-get install osquery

sudo systemctl start osqueryd
sudo systemctl enable osqueryd


sudo filebeat modules enable system
sudo filebeat modules enable auditd
sudo filebeat modules enable suricata
sudo filebeat modules enable osquery

sudo find /etc/filebeat/modules.d -type f -exec sudo sed -i 's/enabled: false/enabled: true/g' {} \;

sudo filebeat setup -e

sudo service filebeat start
