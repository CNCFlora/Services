FROM cncflora/ruby

RUN gem install bundler

RUN mkdir /root/services
ADD Gemfile /root/services/Gemfile
RUN cd /root/services && bundle install

EXPOSE 80
WORKDIR /root/checklist
CMD ["unicorn","-p","80"]

ADD . /root/checklist
