# Deadpool

Named this before I knew of the comic book character. 
I thought I was so clever coming up with such a short descriptive 
name. ¯\\_(ツ)_/¯

## Motivation

We needed a way to provide automated failover on various systems 
where we don't have access to virtual IPs, internal DNS, or any
other industry standard failover solution. And we had TONS of
client apps each with their own infrastructure and a small staff
that REALLY doesn't like getting woken up in the middle of the 
night. What use were all these hot standby DBs if a developer
had to fix every problem anyway?

Something had to be done. Surely a secondary could temorarily take 
over for a primary until staff came in in the morning.

## Goals

- Failover via /etc/hosts.
- Perform ANY auxiliary duties necessary for a successful failover. 
  (i.e. restart job servers, web servers, hang maintenance page, etc..)
- Monitor the status of the entire failover system and report to Nagios.
- Perform or reset the failover manually from the command line.

## Installation

```
$ gem install deadpool
$ deadpool-generator --help
Usage: deadpool-generator command [options]
Commands:
    -h, --help                       Print this help message.
    -u, --upstart_init               Generate and upstart config.
    -c, --configuration              Generate a config directory structure and example files.
Configuration Options:
        --config_path=PATH           path to create the config dir at (/etc/deadpool)
Upstart Options:
        --upstart_config_path=PATH   path to create the config dir at (/etc/init/deadpool.conf)
        --upstart_init_path=PATH     path to create the config dir at (/etc/init.d/deadpool)
        --upstart_script_path=PATH   path to create the config dir at (/lib/init/upstart-job)
```

To scaffold yourself some default configuration run:

```
$ deadpool-generator -c
Configuration saved to /etc/deadpool
```

Below is the directory structure it generates. 

```
$ tree /etc/deadpool/
/etc/deadpool/
|-- config
|   |-- environment.yml
|   `-- pools
|       `-- example.yml

2 directories, 2 files
```

config/environment.yml contains the config for deadpool itself

config/pools/ contains any number of .yml files, one for each service you need to
monitor and failover. eg. redis.yml, mysql.yml, etc.

## Overview

### Monitoring Through Nagios Plugins

The nagios plugin format bacame an industry standard for nearly a decade and the 
plugins are still available on most systems and can be installed as a standalone
package. Whatever you're trying to monitor there is probably already a nagios plugin
written for it. And if there isn't it's dead simple to write your own.

### Chainable Failover Protocols

deadpool can take any number of FailoverProtocols
and execute them in succession in the event of a failover.  Such as 
restarting nginx after making a change to /etc/hosts.

### Multiple Services

Multiple services (ex. mysql, redis, production, staging, etc...) can be
configured under a single instance by putting them all in the same config directory.
Multiple instances can be configured to run on a single box by specifying a separate
configuration directory and admin port for each instance.


### Monitoring

deadpool can test each point in the system and report
when something is out of place.  Meaning it tests more than MySQL, it tests
that all the app servers are pointing at the correct MySQL server and that it has
write permission on /etc/hosts and so on.

```
$ deadpool-admin --nagios_report
OK -  last checked 12 seconds ago.


$ deadpool-admin --full_report
System Status: OK

Deadpool::Server - 
OK - checked 3 seconds ago.

  production_database - Deadpool::Handler
  OK - checked 5 seconds ago.
  Primary Check OK.

      - Deadpool::Monitor::Mysql
    OK - checked 3 seconds ago.
    Primary and Secondary are up.

      - Deadpool::FailoverProtocol::EtcHosts
    OK - checked 2 seconds ago.
    Write check passed all servers: 10.1.2.3, 10.1.2.4
    All client hosts are pointed at the primary.

      - Deadpool::FailoverProtocol::ExecRemoteCommand
    OK - checked 2 seconds ago.
    Exec test passed all servers: 10.1.2.3, 10.1.2.4
```


### How it works

It periodically checks that the primary is okay at an interval of your
choosing. When the primary check has failed enough times in a row to exceed
your threshold it will execute the failover protocol. The failover
protocol is just a list of failover protocols in order. Generally each one
will perform a preflight check first. As each one finishes the failover it
records it's state and success or failure. Once it's all done, deadpool locks
the state so an admin can see what happened and if there were any issues along
the way.

Currently deadpool is a single bullet gun. Once it's failed over, it's done. 
It can perform a manual promotion from the command line but it will have to be
restarted to work again.  This may change in a future release.


## Installation

### Deadpool Server
```
gem install deadpool
sudo deadpool-generator --configuration
/usr/bin/ruby /usr/local/bin/deadpool-admin --foreground --config_path=/etc/deadpool
```

The generator can also install upstart init configuration, but unfortunately
upstart died an early death (RIP) so this has limited utility anymore. Deadpool 
will be updated to generate systemd config or whatever in upcoming releases.

### Client Servers

Manipulating /etc/hosts is not without risk so a dedicated script is installed
with the deadpool gem to handle it. Therefore the gem needs to be installed on
each server whose /etc/hosts file you need to manipulate in the event of a 
failover. Deadpool currently performs failover by exec'ing commands over ssh. 
Take your own security precautions on the client hosts as you see fit. Here's 
an example below:

```
$ gem install deadpool
$ sudo adduser deadpool
$ sudo chgrp deadpool /etc/hosts
$ sudo chmod 664 /etc/hosts
$ which deadpool-hosts
```

## Configuration

The configuration is only stored on the deadpool server. By default configuration
is stored in /etc/deadpool. Below is /etc/deadpool/config/pools/example.yml

```yaml
pool_name: 'production_database'
check_interval: 3
max_failed_checks: 10
primary_host:   10.x.x.x
secondary_host: 10.x.x.x

monitor_config:
  monitor_class: Mysql
  name: 'Database Monitor'
  nagios_plugin_path: '/usr/lib/nagios/plugins/check_mysql'
  username: 'db_admin'
  password: 'passwerd'

failover_protocol_configs:
  - protocol_class: EtcHosts
    name: 'Change Hosts'
    script_path: '/usr/local/bin/deadpool-hosts'
    service_host_name: 'unique.production.database.name'
    username: 'deadpool'
    password: 'passwerd'
    client_hosts:
      - '10.x.x.x' # app1
      - '10.x.x.x' # app2
      - '10.x.x.x' # app3
      - '10.x.x.x' # app4
      - '10.x.x.x' # jobserver

  - protocol_class: ExecRemoteCommand
    name: 'Restart Nginx'
    test_command: '/etc/init.d/nginx status'
    exec_command: '/etc/init.d/nginx restart'
    username: 'deadpool'
    password: 'passwerd'
    client_hosts:
      - '10.x.x.x' # app1
      - '10.x.x.x' # app2
      - '10.x.x.x' # app3
      - '10.x.x.x' # app4

  - protocol_class: ExecRemoteCommand
    name: 'Restart Job Service'
    test_command: '/etc/init.d/monit test'
    exec_command: '/etc/init.d/monit restart'
    username: 'deadpool'
    password: 'passwerd'
    use_sudo: 1
    client_hosts:
      - '10.x.x.x' # jobserver
```

### Putting it all together

Once it's installed, configured and running you should be able to get 
the status of the system by running asking deadpool-admin for a full report.

```
  $ deadpool-admin --full_report
```
  
If the server is up and it can write to the /etc/hosts file on all the app 
servers you can use the following command to add the new entry to 
/etc/hosts on all your app servers.

```
  $ deadpool-admin --promote_server --server=primary_host --pool=production_database
  $ deadpool-admin --full_report
```

If deadpool reports everything is okay you can now connect it to Nagios via 
the built in Nagios reporting flag.  Keep in mind that for the Nagios check 
is cached from the last system check.  --full_report is not cached.

```
  $ deadpool-admin --nagios_report
  OK -  last checked 16 seconds ago.
```

If deadpool reports check out OK then you should be ready for primetime.  
You can configure your app to connect to the database via the 
service_host_name (unique.production.database.name according to the 
above config example).