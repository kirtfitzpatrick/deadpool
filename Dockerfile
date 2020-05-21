FROM ubuntu:focal AS base
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    bat \
    g++ \
    gcc \
    make \
    ruby \
    ruby-dev \
    ssh \
    tree \
    vim 
WORKDIR /opt


FROM base AS build
COPY . .
RUN gem build deadpool.gemspec


FROM base AS dev
COPY --from=build /opt/deadpool-*.gem /tmp/
RUN gem install --development --no-document /tmp/deadpool-*.gem
ENTRYPOINT [ "/bin/bash" ]


FROM build AS test
RUN gem install --development --no-document deadpool-*.gem
ENTRYPOINT ["rake"]


FROM build AS deadpool
RUN gem install --no-document deadpool-*.gem 


FROM deadpool AS app
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:password' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
ENTRYPOINT ["/usr/sbin/sshd", "-D"]


FROM deadpool AS monitor
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    monitoring-plugins \
    mysql-client
RUN mkdir -p /etc/deadpool/pools
RUN cp -R /opt/docker/etc/* /etc/deadpool/
ENTRYPOINT ["/bin/bash"]
