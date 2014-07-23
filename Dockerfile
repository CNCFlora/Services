FROM cncflora/ruby

RUN gem install bundler
ADD Gemfile /root/occurrences/Gemfile

RUN mkdir /root/services
ADD Gemfile /root/services/Gemfile
RUN cd /root/services && bundle install
ADD . /root/services

ENV ENV production
ENV RACK_ENV production
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]

