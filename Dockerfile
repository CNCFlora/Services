# CNCFlora Services 

FROM stackbrew/ubuntu:raring
MAINTAINER Diogo "kid" <diogo@diogok.net>

ENV APP_USER cncflora 
ENV APP_PASS cncflora

RUN useradd -g users -s /bin/bash -m $APP_USER
RUN echo $APP_USER:$APP_PASS | chpasswd

RUN cp /etc/apt/sources.list /etc/apt/sources.list.bkp && sed -e 's/http/ftp/g' /etc/apt/sources.list.bkp > /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get install ruby1.9.3 curl git vim openssh-server tmux -y

RUN mkdir /var/run/sshd 

#RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7 && gpg --armor --export 561F9B9CAC40B2F7 | sudo apt-key add -
#RUN apt-get install apt-transport-https -y
#RUN echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger raring main" >> /etc/apt/sources.list
#RUN apt-get update -y && apt-get install nginx-full passenger -y

RUN gem sources -r http://rubygems.org/ && gem sources -r http://rubygems.org && gem sources -a https://rubygems.org
RUN gem install bundler

RUN cd /home/$APP_USER/ && su $APP_USER -c 'git clone https://github.com/CNCFlora/Services.git www'
RUN cd /home/$APP_USER/www && bundle install

EXPOSE 22
#EXPOSE 80
EXPOSE 8080

ADD config.yml /root/config.yml
RUN cp /root/config.yml /home/$APP_USER/www && chown $APP_USER /home/$APP_USER/www/config.yml && rm /root/config.yml
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

CMD ["/root/start.sh"]

