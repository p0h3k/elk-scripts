# Устанавливаем версию
version=8.10.2

# Устанавливаем необходимые пакеты
sudo apt-get install wget rpm jq -y

# Скачиваем filebeat
wget http://mirrors.aliyun.com/elasticstack/yum/elastic-8.x/$version/filebeat-$version-x86_64.rpm

# Устанавливаем filebeat
sudo rpm --install --nodeps filebeat-$version-x86_64.rpm

# Получаем IP-адрес сервера от пользователя
echo "Enter Server IP: "
read client_ip

# Изменяем настройки filebeat
sudo sed -i 's/#host: "localhost:5601"/host: "localhost:5601"/g' /etc/filebeat/filebeat.yml
sudo sed -i 's/#username: "elastic"/username: "elastic"/g' /etc/filebeat/filebeat.yml
sudo sed -i 's/#password: "changeme"/password: "changeme"/g' /etc/filebeat/filebeat.yml

# Заменяем localhost на IP-адрес клиента
sudo sed -i "s/localhost/${client_ip}/g" /etc/filebeat/filebeat.yml

# Устанавливаем и запускаем auditd
sudo apt-get install auditd -y
sudo systemctl start auditd
sudo systemctl enable auditd

# Добавляем репозиторий suricata
sudo add-apt-repository ppa:oisf/suricata-stable

# Устанавливаем и активируем suricata
sudo apt install suricata -y 
sudo systemctl enable suricata.service

# Включаем community-id в настройках suricata
sudo sed -i 's/community-id: false/community-id: true/g' /etc/suricata/suricata.yaml

# Получаем название активного сетевого интерфейса
interface=$(ip -p -j route show default | jq -r '.[0].dev')

# Заменяем имя интерфейса в настройках suricata
sudo sed -i "s/interface: eth0/interface: ${interface}/g" /etc/suricata/suricata.yaml

# Добавляем строки в конфигурацию suricata
sudo echo 'detect-engine:' >> /etc/suricata/suricata.yaml
sudo echo '  - rule-reload: true' >> /etc/suricata/suricata.yaml

# Обновляем suricata
sudo suricata-update

# Копируем правила suricata
sudo cp /var/lib/suricata/rules/suricata.rules /etc/suricata/
sudo suricata -T -c /etc/suricata/suricata.yaml -v

# Запускаем suricata
sudo systemctl start suricata.service

# Добавляем репозиторий osquery
export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys $OSQUERY_KEY
sudo add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'

# Обновляем и устанавливаем osquery
sudo apt-get update -y
sudo apt-get install osquery

# Запускаем и активируем osquery
sudo systemctl start osqueryd
sudo systemctl enable osqueryd

# Активируем необходимые модули filebeat
sudo filebeat modules enable system
sudo filebeat modules enable auditd
sudo filebeat modules enable suricata
sudo filebeat modules enable osquery

# Включение всех модулей в /etc/filebeat/modules.d
sudo find /etc/filebeat/modules.d -type f -exec sudo sed -i 's/enabled: false/enabled: true/g' {} \;

# Настраиваем filebeat
sudo filebeat setup -e

# Запускаем filebeat
sudo service filebeat start
