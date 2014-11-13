FROM cncflora/ruby

RUN gem install bundler
RUN mkdir /root/services
ADD Gemfile /root/services/Gemfile
RUN cd /root/services && bundle install

ADD supervisord.conf /etc/supervisor/conf.d/services.conf

EXPOSE 8080

ADD . /root/services

