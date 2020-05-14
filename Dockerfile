FROM ubuntu:focal

RUN apt-get update 
RUN apt-get install -y gcc g++ make ruby ruby-dev ssh

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y monitoring-plugins mysql-client

RUN apt-get install -y tree bat vim

WORKDIR /opt
COPY . .

RUN gem install --no-document deadpool-1.0.0.gem 

# docker compose stuff
RUN mkdir -p /etc/deadpool/pools
RUN cp -R /opt/docker/etc/* /etc/deadpool/

ENTRYPOINT ["/bin/bash"]