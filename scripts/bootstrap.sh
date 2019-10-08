#!/usr/bin/env bash

TIME_ZONE_FILE=/usr/share/zoneinfo/Asia/Tokyo

printLog() {
  printf "[$1-$0] $1\n";
}

install_wget() {
  value=$(rpm -qa | grep -c ^wget)
  if [ $value -eq 0 ]; then
    printLog "Installing wget";
    sudo yum --nogpgcheck --quiet -y install wget
  fi
}

install_adoptopenjdk_11_hotspot() {
  value=$(rpm -qa | grep -c ^java)
  if [ $value -eq 0 ]; then
    printLog "Installing adoptopenjdk-11-hotspot-11";
    sudo yum --quiet -y install adoptopenjdk-11-hotspot-11.0.3+7-1.$(uname -m)
    echo 'export JAVA_HOME=/usr/lib/jvm/adoptopenjdk-11-hotspot' | sudo tee -a /etc/profile.d/java.sh
    echo 'export JRE_HOME=/usr/lib/jvm/adoptopenjdk-11-hotspot' | sudo tee -a /etc/profile.d/java.sh
    source /etc/profile
  fi
}

install_kafka() {
  FILE=/home/vagrant/kafka
  if [[ ! -f ${FILE} ]]; then
    printLog "Installing Apache Kafka";
    sudo wget -q https://archive.apache.org/dist/kafka/2.1.1/kafka_2.11-2.1.1.tgz
    sudo mkdir -p /home/vagrant/kafka && sudo tar xvf kafka_2.11-2.1.1.tgz -C /home/vagrant/kafka --strip-components=1
    rm -rf kafka_2.11-2.1.1.tgz
  fi
}

install_postgresql11_server() {
  value=$(rpm -qa | grep -c ^postgresql11-server)
  if [ $value -eq 0 ]; then
    printLog "Installing postgresql11-server";
    sudo rpm -Uvh https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    sudo yum --nogpgcheck --quiet -y install postgresql11 postgresql11-server
    sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'      /" /var/lib/pgsql/11/data/postgresql.conf
    echo "host    all             all             all                     md5" >> /var/lib/pgsql/11/data/pg_hba.conf
    sudo systemctl enable postgresql-11.service
    sudo systemctl start postgresql-11.service
    cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER vagrant WITH PASSWORD 'vagrant' CREATEDB;

-- Create the database:
CREATE DATABASE vagrant WITH OWNER=vagrant
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
EOF
   fi
}

node_ip=$1

sudo tee "/vagrant/scripts/common.sh" > /dev/null <<EOF
#!/usr/bin/env bash

node_ip=$node_ip
zk_port=2181
kafka_port=9092

zk=\${node_ip}:\$zk_port
broker=\${node_ip}:\$kafka_port

kafka_home=/home/vagrant/kafka
EOF

source "/vagrant/scripts/common.sh"

sudo tee "/etc/yum.repos.d/adoptopenjdk.repo" > /dev/null <<EOF
[AdoptOpenJDK]
name=AdoptOpenJDK
baseurl=https://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/7/$(uname -m)
enabled=1
gpgcheck=1
gpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public
EOF

sudo yum update

install_adoptopenjdk_11_hotspot
install_wget
install_kafka
install_postgresql11_server



chown vagrant:vagrant -R /home/vagrant/
chmod u+x /vagrant/scripts/*.sh
