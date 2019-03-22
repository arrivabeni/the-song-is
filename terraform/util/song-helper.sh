#!/bin/bash

########### Update and Install ###########

yum update -y
yum install wget -y
yum install unzip -y
yum install java-1.8.0-openjdk-devel.x86_64 -y
yum install git -y
yum install maven -y

######## Song Helper Application #########

cd /tmp
git clone https://github.com/riferrei/the-song-is.git
cd the-song-is/song-helper
mvn clean
mvn compile
mvn install
cd target
mkdir /etc/song-helper
cp song-helper-spring-boot-1.0.jar /etc/song-helper

cat > /etc/song-helper/start.sh <<- "EOF"
#!/bin/bash

export BOOTSTRAP_SERVERS=${broker_list}
export ACCESS_KEY=${access_key}
export ACCESS_SECRET=${secret_key}

export CLIENT_ID=${client_id}
export CLIENT_SECRET=${client_secret}
export ACCESS_TOKEN=${access_token}
export REFRESH_TOKEN=${refresh_token}
export DEVICE_NAME='${device_name}'

java -jar /etc/song-helper/song-helper-spring-boot-1.0.jar
EOF

chmod 775 /etc/song-helper/start.sh

########### Creating the Service ############

cat > /lib/systemd/system/jaeger-agent.service <<- "EOF"
[Unit]
Description=Jaeger Agent
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/jaeger/jaeger-1.10.0-linux-amd64/jaeger-agent --config-file=/etc/jaeger/jaeger-1.10.0-linux-amd64/jaeger-agent.yaml

[Install]
WantedBy=multi-user.target
EOF

cat > /lib/systemd/system/spring-server.service <<- "EOF"
[Unit]
Description=Spring Boot Application
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=/etc/the-song-is/start.sh

[Install]
WantedBy=multi-user.target
EOF

########### Enable and Start ###########

systemctl enable jaeger-agent
systemctl start jaeger-agent

systemctl enable spring-server
systemctl start spring-server