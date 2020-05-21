# Deadpool

The failover option of last resort. Seriously, if you can handle
failover any way other than /etc/hosts you should do that.

Named this before I knew of the comic book character. I thought 
I was sooo clever coming up with such a short yet descriptive 
name. ¯\\_(ツ)_/¯

## Goals

- Failover via /etc/hosts.
- Autonomously handle any and all tasks necessary for a successful failover. 
  (i.e. restart job servers, web servers, hang maintenance page, etc..)
- Perform or reset the failover manually from the command line.
- Monitor **everything**
  - health of the primary
  - health of the secondary
  - is each client:
    - reachable?
    - pointing where it should be? (primary/secondary)
  - health of the failover protocols. i.e. Have all protocol checks passed on all clients?

## Docker Demo

If you have Docker Desktop try it out locally. Also if you want to modify
or contribute to it this is the local development environment.

```console
$ git clone git@github.com:kirtfitzpatrick/deadpool.git
$ cd deadpool
$ ./build.sh --demo
```

Play around with it to make sure it's working:

```console
$ docker-compose ps
$ docker-compose exec monitor deadpool --full_report
$ docker-compose exec monitor deadpool --nagios_report
$ docker-compose exec monitor deadpool --promote --pool=mysql --server=secondary
$ docker-compose exec monitor deadpool --promote --pool=mysql --server=primary
```

Now shoot the primary in the head and see if deadpool jumps into action.

```console
$ docker-compose stop db1 && docker-compose logs -f --tail=5
```


## Installation

### Scripts

Deadpool comes packaged with three scripts. Use --help to learn more

- deadpool-gen - generates configuration for the server
- deadpool - cli tool to communicate with the deadpool service
- deadpool-hosts - client script to check and manipulate /etc/hosts

### Client Side Installation

Manipulating /etc/hosts is not without risk so a dedicated script is installed
with the deadpool gem to handle it. Therefore the gem needs to be installed on
each server whose /etc/hosts file you need to manipulate in the event of a 
failover. 

```console
$ gem install deadpool
```

Deadpool currently performs failover by exec'ing commands over ssh. 
Take your own security precautions on the client hosts as you see fit. Here's 
an example below:

```console
$ adduser deadpool
$ chgrp deadpool /etc/hosts
$ chmod 664 /etc/hosts
```

Setup the hosts file and verify it's working:

```console
$ su - deadpool
$ deadpool-hosts --test                                                                       
OK - /etc/hosts is writable
$ deadpool-hosts --verify --host_name=deadpool.test.hostname --ip_address=127.0.0.1
ERROR - deadpool.test.hostname does not point at 127.0.0.1
$ deadpool-hosts --switch --host_name=deadpool.test.hostname --ip_address=127.0.0.1
OK - Host definition added successfully.
$ deadpool-hosts --verify --host_name=deadpool.test.hostname --ip_address=127.0.0.1
OK - deadpool.test.hostname was verified to point at 127.0.0.1
$ deadpool-hosts --verify --host_name=deadpool.test.hostname --ip_address=127.0.0.2
ERROR - deadpool.test.hostname does not point at 127.0.0.2
$ deadpool-hosts --switch --host_name=deadpool.test.hostname --ip_address=127.0.0.2
OK - Host definition replaced successfully.
$ deadpool-hosts --verify --host_name=deadpool.test.hostname --ip_address=127.0.0.2
OK - deadpool.test.hostname was verified to point at 127.0.0.2
$ cat /etc/hosts
127.0.0.1	localhost
...
127.0.0.2  deadpool.test.hostname
```

### Server Side Installation

Install some nagios plugins to get you started. No point reinventing the wheel if
there's already a nagios plugin for it.

```console
$ apt-get install -y monitoring-plugins
```

In deadpool world, all the knowledge, configuration and services live on the deadpool
server. Usually this would also be a monitoring server or similar. Install the gem 
on the server and generate comfigs.

```console
$ gem install deadpool
$ deadpool-gen -c
Configuration saved to /etc/deadpool
$ tree /etc/deadpool
/etc/deadpool
|-- system.yml
`-- pools
    `-- example.yml

1 directory, 2 files
```

Look around in the generated configs and add your real information to them.
Probably change the log level to DEBUG until you get everything sorted.
Start the server with the following command:

```console
$ /usr/bin/ruby /usr/local/bin/deadpool --foreground
```

The generator can also install upstart init configuration, but unfortunately
upstart died far too young (RIP) so this has limited utility anymore. Hopefully
I'll update this to whatever the flavor of the month is in an upcoming release.


### Putting it all together

If the server is up and it can write to the /etc/hosts file on all the app 
servers you can use the following command to add the new entry to 
/etc/hosts on all your app servers.

```console
$ deadpool --promote --pool=mysql --server=primary
```

Once it's installed, configured and running you should be able to get 
the status of the system by running asking deadpool for a full report.

```console
$ deadpool --full_report
System Status: OK

Deadpool::Server
OK - checked 3 seconds ago.

  production_database - Deadpool::Handler
  OK - checked 5 seconds ago.
  Primary Check OK.

    Deadpool::Monitor::Mysql
    OK - checked 3 seconds ago.
    Primary and Secondary are up.

    Deadpool::FailoverProtocol::EtcHosts
    OK - checked 2 seconds ago.
    Write check passed all servers: 10.1.2.3, 10.1.2.4
    All client hosts are pointed at the primary.

    Deadpool::FailoverProtocol::ExecRemoteCommand
    OK - checked 2 seconds ago.
    Exec test passed all servers: 10.1.2.3, 10.1.2.4
```
  
If deadpool reports everything is okay you can now connect it to Nagios via 
the built in Nagios reporting flag.  Keep in mind that for the Nagios check 
is cached from the last system check.  --full_report is not cached.

```console
$ deadpool --nagios_report
OK -  last checked 16 seconds ago.
```

If deadpool reports check out OK then you should be ready for primetime.  
You can configure your app to connect to the database via the 
service_host_name you specified in pools/foo_service.yml.
