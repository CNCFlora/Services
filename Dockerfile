FROM cncflora/ruby

RUN mkdir /root/services
ADD . /root/services
RUN cd /root/services && \
    gem install bundler && \
    bundle install

ENV ENV production
ENV RACK_ENV production
ADD start.sh /root/start.sh
RUN chmod +x /root/start.sh

EXPOSE 8080

CMD ["/root/start.sh"]

