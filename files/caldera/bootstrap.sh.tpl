#!/bin/bash

set -e
CALDERA_SSL_PORT=8443
#exec > >(sudo tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Start bootstrap script"
sudo apt-get update -y
sudo apt-get install net-tools -y
sudo apt-get install unzip -y



# Caldera install
echo "Installing Caldera"
echo "Installing some packages for Caldera"
sudo adduser --system --group caldera
sudo apt-get install -y apt-transport-https ca-certificates gnupg2 
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa --yes
sudo apt install upx -y
sudo apt install python3.9 -y
sudo apt install python3-pip -y
sudo apt-get install haproxy -y
# Upgrade pyOpenSSL - weird issue only impacting AWS EC2 AMI images
sudo pip3 install --upgrade pyOpenSSL

# Install NodeJS for Caldera 5.0 requirement
cd ~
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash - &&\
sudo apt-get install -y nodejs

# Downloading Caldera
echo "Downloading Caldera"
cd /opt
sudo git clone https://github.com/mitre/caldera.git --recursive

# Caldera SSL cert
cd /opt/caldera/conf
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_DNS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-hostname)
export INSTANCE_PUBLIC_DNS=$PUBLIC_DNS
openssl genpkey -algorithm RSA -out key.pem -pkeyopt rsa_keygen_bits:2048
openssl req -new -x509 -key key.pem -out certificate.pem -days 365 -subj "/C=US/ST=New York/L=New York City/O=Your Organization/OU=Caldera/CN=$INSTANCE_PUBLIC_DNS" 

# Get caldera.service 
echo "Get caldera.service"
file="caldera.service"
object_url="https://${s3_bucket}.s3.${region}.amazonaws.com/$file"
echo "Downloading s3 object url: $object_url"
for i in {1..5}
do
    echo "Download attempt: $i"
    curl "$object_url" -o /opt/caldera/caldera.service

    if [ $? -eq 0 ]; then
        echo "Download successful."
        break
    else
        echo "Download failed. Retrying..."
    fi
done

#Caldera SSL setup
echo "Modifying caldera configuration files"
sudo cp plugins/ssl/templates/haproxy.conf conf/haproxy.conf
sed -i 's/insecure_certificate.pem/certificate.pem/' conf/haproxy.conf
#sed -i "s|http://0.0.0.0:8888|https://$INSTANCE_PUBLIC_DNS:8443|" conf/local.yml
#sed -i "s|host: 0.0.0.0|host: $INSTANCE_PUBLIC_DNS|" conf/local.yml




# end of Caldera install



echo "End of bootstrap script"
