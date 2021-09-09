#! /bin/bash
yum  update -y
yum install python3 -y
yum install wget unzip -y
yum remove docker docker-common docker-selinux docker-engine-selinux docker-engine docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
yum install -y  http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-3.el7.noarch.rpm
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y \ docker-ce \ docker-ce-cli \ containerd.io
usermod -a -G docker ec2-user
systemctl start docker.service
systemctl enable docker.service
cd /home/ec2-user/
wget https://github.com/mehmetafsar510/aws_devops/raw/master/teamwork-agendas/react.zip
unzip react.zip
cd /home/ec2-user/react
sed -i "s/{nodejs_dns_name}/${nodejs_dns_name}/g" .env
docker build -t "mehmet/react_artf" .
docker run -d -p 80:80 mehmet/react_artf
