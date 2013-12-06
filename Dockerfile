# CNCFlora Services 

FROM stackbrew/ubuntu:raring
MAINTAINER Diogo "kid" <diogo@diogok.net>

ENV USER cncflora 
ENV PASS cncflora

RUN useradd -g users -s /bin/bash -m $USER
RUN echo $USER:$PASS | chpasswd

RUN cp /etc/apt/sources.list /etc/apt/sources.list.bkp && sed -e 's/http/ftp/g' /etc/apt/sources.list.bkp > /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get install ruby curl git vim openssh-server -y

RUN mkdir /var/run/sshd 

#RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 && gpg --armor --export 561F9B9CAC40B2F7 | sudo apt-key add -
#RUN apt-get install apt-transport-https -y
#RUN echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger raring main" >> /etc/apt/sources.list
#RUN apt-get update -y && apt-get install nginx-full passenger -y

RUN gem sources -r http://rubygems.org/ && gem sources -r http://rubygems.org && gem sources -a https://rubygems.org
RUN gem install bundler

RUN cd /home/$USER/ && su $USER -c git clone https://github.com/CNCFlora/Services.git www
RUN cd /home/$USER/www && su $USER -c 'bundle install' 

EXPOSE 22
#EXPOSE 80
EXPOSE 8080

ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

CMD ["/root/start.sh"]

