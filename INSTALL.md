# Installation

## Requirements

### compilers
For the compilation of JRuby several compilers are needed. They can be
installed in several ways. The compilers needed are:

```
git gcc gcc-c++
```

### apache
The software requires apache/httpd daemon.
The apache/httpd parts needed are:

```
apache-tomcat-apis mod_ssl
```
**NOTE:** for Centos 7 other packages are needed. They are:
```
tomcat-jsp-2.2-api tomcat-servlet-3.0-api mod_ssl
```

### password generator
A password is needed for the epic users. Included in the EPIC API is a script
which generates passwords. It depends on the following tool:

```
pwgen
```

### mysql
The handle system and the EPIC-API talk directly to a mysql database. A
mysql-server needs to be installed. The following packages are needed:

```
mysql-server mysql-connector-java
```

The mysql database schema is provided. It is: `schema.sql`. Create a database
with the supplied schema. Give read/write acces to a dedicated user.

**NOTE:** for Centos 7 other packages are needed. They are:
```
mariadb-server mysql-connector-java
```

### Handle System v7
You will need a running Handle System installation.
Details can be found at the [Handle System web site](http://www.handle.net/).
An option would be to install the software under `opt` as the user root:

Install hsj as the root user

```bash
cd /opt
tar -xvf hsj-7.3.1.tar --no-same-owner
ln -s /opt/hsj-7.3.1  hsj
export PATH=$PATH:/opt/hsj/bin/
```

This gives that `HS_DISTRO_ROOT == /opt/hsj`.

The configuration for the handle server could be put under `$HOME/etc`. The
handle server normally run's as an non-privileged user.

Perform the setup of the server as the non-privileged user (see also
documentation at the [Handle System web site](http://www.handle.net/):
```
export PATH=$PATH:/opt/hsj/bin/
hdl-setup-server $HOME/etc
```

The mysql database has to be used by the handle server. The handle server uses
a mysql database if following is added in `config.dct` in the `server_config`
section:

```
"storage_type" = "sql"
"sql_settings" = {
    "sql_url" = "jdbc:mysql:///<handle_database>"
    "sql_driver" = "com.mysql.jdbc.Driver"
    "sql_login" = "<handle_database_user>"
    "sql_passwd" = "<handle_database_user_password>"
    "sql_read_only" = "no"
}
```

The handle system needs to know the location of the mysql connector. Create a
symbolic link inside the handle server lib directory called
`mysql-connector-java.jar`, pointing to
`$JAVA_DISTRO_ROOT/mysql-connector-java.jar`

```bash
cd $HS_DISTRO_ROOT/lib
ln -s /usr/share/java/mysql-connector-java.jar 
```

Normally the handle server is case insensitive. But the handles created, updated
and retrieved via the EPIC API are case sensitive. Put the handle server in
case sensitive mode to be consistent. This is done by modifying following in
`config.dct` in the `server_config` section:

```
"case_sensitive" = "yes"
```


**NOTE:** Make sure that in the `config.dct` the index of the different admins
is different and **NOT** the same. An example is as follows:
```
    "server_admins" = (
      "300:0.NA/10916"
    )

    "replication_admins" = (
      "301:0.NA/10916"
      "302:0.NA/10916"
    )

    "backup_admins" = (
      "310:0.NA/10916"
    )
```
Here the indexes are: 300, 301, 302 and 310 with prefix 10916. Index 300 is
used for the server. Index 301 and 302 are used for replications to other
handle servers and Index 310 is used for backup purposes.

### JRuby
First of all, this software requires JRuby, as it interfaces with the Java
client library of the Handle System. JRuby can be installed in many ways. An
easy supported way is to download the jruby tarball and install/upack it.You
can go to the [JRuby web site](http://jruby.org/) and download it from there.


Perform the following actions as the user root.

Install jruby as the root user

```bash
cd /opt
tar -xvf /tmp/jruby-bin-1.7.11.tar-2.gz --no-same-owner
ln -s jruby-1.7.11 jruby
export PATH=$PATH:/opt/jruby/bin/
jruby -v
```

After installing JRuby, add the path for the jruby command and make sure that
the interpreter runs in _1.9_ _mode_. This is done by adding the path to the
jruby binary to the $PATH environment variable, and adding option `--1.9` to
environment variable `JRUBY_OPTS`. An example for `.bashrc` is:

```bash
export PATH=$PATH:/opt/jruby/bin/
export JRUBY_OPTS="--1.9 -J-Djruby.thread.pool.enabled=true"
```

After this install the necessary gems as the user root

```bash
jruby -S gem list --local
```
    
### Sequel
Sequel is a Ruby database abstraction layer and Object-Relational Mapper (ORM).
For performance reasons, we don not use the ORM features.

Depending on the kind of database you are using underneath the Handle System,
you will probably need to install some database handler as well.
The service developers use gem `jdbc-mysql` in order to connect to their
MySQL databases.

### Rack
Rack provides a minimal, modular and adaptable interface for developing web
applications in Ruby. By wrapping HTTP requests and responses in the simplest
way possible, it unifies and distills the API for web servers, web frameworks,
and software in between (the so-called middleware) into a single method call.
Also see http://rack.github.com/. 

### Mizuno
mizuno are a pair of Jetty-powered running shoes for JRuby/Rack.

### Json_pure
This is a JSON implementation in pure Ruby.

### Choice
Choice is a simple little gem for easily defining and parsing command line
options with a friendly DSL.

```bash
jruby -S gem install  sequel jdbc-mysql rack mizuno json_pure choice childprocess ffi 
```

### Rackful
[Rackful](http://pieterb.github.com/Rackful/) is a library to build ReSTful web
services on top of [Rack](http://rack.rubyforge.org/doc/).

You might want to read the
[Rack interface specification](http://rack.rubyforge.org/doc/SPEC.html)
and [other Rack documentation]() as well. You will need a version 0.1.x of
rackful. It can be downloaded from: https://rubygems.org/gems/rackful.
version 0.2.x of rackful is NOT compatible with the EPIC-API.

```bash
jruby -S gem install  rackful -v 0.1.4
```


## Installation

The EPIC API is tightly coupled the handle server which it connects to. It has
to be run as the same user as the handle server is running. The EPIC API is
installed as follows:

### EPIC API
create a directory and unzip the package in that directory (Use the same user as the
handle server is running under). An example would be:

```
cd
unzip EPIC_API in to $HOME/epic_v2_prod_<prefix>
```

or

```bash
cd 
mkdir git ; cd git
git clone git://github.com/pidconsortium/EPIC-API-v2.git
cd
ln -s git/EPIC-API-v2 epic_v2_prod_<prefix>
```

The web service needs to know the location of your Handle System installation.
Create a symbolic link inside the Web Service top level directory called `hsj`,
pointing to `$HS_DISTRO_ROOT/lib`.

```bash
cd epic_v2_prod_<prefix>
ln -s <directory_handle_service>/hsj/lib hsj
```

## Configuration

The web service comes preconfigured for HTTP Digest authentication.
You will need to create two configuration files for this to work, though:

### General configuration
The default installation expects some configuration information in file
`config.rb` and `config.ru`. You will find a sample configuration files called
`config.rb.example` and `config.ru.example` in the distribution. Copy these
files to working config's:

```bash
cp -a config.rb.example config.rb
cp -a config.ru.example config.ru
```

#### config.rb
The following parameters have to be adapted in the `config.rb`:
* REALM. The realm name used in basic and digest authentication.
* OPAQUE. This is a radom hex string of 32 characters used for digest authentication.
* SEQUEL_CONNECTION_ARGS. Fill here YOUR_DATABASE, YOUR_USER and YOUR_PASSWD.
* LOG_SETTINGS. Modify as you like.
* NO_DELETE. A regular expression to define for which prefix deletes are prohibited.
* ENFORCED_PROFILES. The default profile should be "nodelete".
* DEFAULT_GENERATOR. The default generator for suffixes. should be "uuid".

There is more info about these parameters in the `config.rb` file.

#### config.ru
The following lines have to be adapted in the `config.ru`: 
* The first line in config.ru can have the port on which the epic server
listens. It is in the format of:
```
#\ --port 9292 --server mizuno
```
* If Apache is used modify config.ru to have the correct url returned:

```ruby
# When run behind an Apache reverse proxy server, the original request scheme
# (http or https) gets lost. This config works around this for epic_1.0.0:
#use Rack::Config do
#  |env|
#  env['HTTP_X_FORWARDED_SSL'] = 'on'
#end
use Rack::Config do
  |env|
   env.keys.each do
     |key|
       env.delete(key) if /^http_x_forwarded_/i === key
   end
end
```

### User accounts
In the default configuration, account information is expected in file
`secrets/users.rb`. From the installation root, do the following:

```bash
cd secrets/
cp -a users.rb.example users.rb
$EDITOR users.rb
```

The passwords are hashed in the field "digest". It is the MD5 checksum of
"<username>:<REALM>:<password>".

For the communication with the handle service a key has to be present in the
`secrets` directory. It must have the format `300_0_NA_prefix`

an example is following:

```
300_0_NA_prefix -> <handle_configuration_directory>/privkey.bin
```

### Apache 

The file /etc/httpd/conf.d/ssl.conf has the following addition.

```
ProxyPass /v2/ http://localhost:9292/
ProxyPassReverse /v2/ http://localhost:9292/
ProxyPassReverseCookieDomain localhost:9292 <fully_qualified_hostname>
ProxyPassReverseCookiePath / /v2/
```

Apache acts as a proxy. HTTPS traffic is routed to localhost port 9292. This 
is the port where the epic server v2 listens. So everything which starts with /v2/ is
routed/proxied to the EPIC service.

## Running!


At this point, you should be able to start the web service:

```bash
rackup
```

By default, this will start a mizuno web server, listening to port 9292.

If you would like to use another web server, another port number, another
authentication method, then check out the Rack documentation, and start editing
the rackup configuration file `config.ru`. That files contains a lot of in-line
documentation that hopefully gets you started.

At this time a https request can be done to: `https://<fully_qualified_hostname>/v2/handles/`


