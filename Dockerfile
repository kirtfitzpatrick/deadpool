FROM ubuntu:focal
RUN apt-get update && apt-get install -y ruby
# Packages needed to install eventmachine
RUN apt-get install -y gcc g++ make
# Packages needed to install deadpool
RUN apt-get install -y ruby-dev
RUN apt-get install -y tree

WORKDIR /opt
COPY . .

RUN gem install --no-document deadpool-1.0.0.gem 

ENTRYPOINT ["/bin/bash"]