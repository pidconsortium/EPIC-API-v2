Installation
============

Requirements
------------
### compilers
For the compilation of JRuby several compilers are needed. They can be
installed in several ways. The compilers needed are: 
`git gcc gcc-c++ ant`

### apache
The software requires apache/httpd daemon.
The apache/httpd parts needed are:
`apache-tomcat-apis mod_ssl`

### password generator
A password is needed for the epic users. Included in the EPIC API is a script
which generates passwords. It depends on the following tool:

`pwgen`

### Handle System v7
You will need a running Handle System installation.
Details can be found at the [Handle System web site](http://www.handle.net/).
The handle system needs to be installed with a mysql database. The mysql
database schema is provided. It is: `schema.sql`
The mysql database has to be used by the handle server. The handle server uses
a mysql database if following is added in `config.dct` in the `server_config`
section:

    "storage_type" = "sql"
    "sql_settings" = {
      "sql_url" = "jdbc:mysql:///<handle_database>"
      "sql_driver" = "com.mysql.jdbc.Driver"
      "sql_login" = "<handle_database_user>"
      "sql_passwd" = "<handle_database_user_password>"
      "sql_read_only" = "no"
    }


The handle system needs to know the location of the mysql connector. Create a
symbolic link inside the handle server lib directory called
`mysql-connector-java.jar`, pointing to
`$JAVA_DISTRO_ROOT/mysql-connector-java.jar`

    cd $HS_DISTRO_ROOT/lib
    ln -s /usr/share/java/mysql-connector-java.jar 


### JRuby
First of all, this software requires JRuby, as it interfaces with the Java
client library of the Handle System. JRuby can be installed in many ways. An
easy supported way is to download the jruby tarball and install/upack it.You
can go to the [JRuby web site](http://jruby.org/) and download it from there.


Perform the following actions as the user root.

Install jruby as the root user

    cd /opt
    tar -xvf /tmp/jruby-bin-1.7.11.tar-2.gz --no-same-owner
    ln -s jruby-1.7.11 jruby
    export PATH=$PATH:/opt/jruby/bin/
    jruby -v


After installing JRuby, add the path for the jruby command and make sure that
the interpreter runs in _1.9_ _mode_. This is done by adding the path to the
jruby binary to the $PATH environment variable, and adding option `--1.9` to
environment variable `JRUBY_OPTS`. An example for `.bashrc` is:


    export PATH=$PATH:/opt/jruby/bin/
    export JRUBY_OPTS="--1.9 -J-Djruby.thread.pool.enabled=true"


After this install the necessary gems as the user root

    jruby -S gem list --local

    
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


    jruby -S gem install  sequel jdbc-mysql rack mizuno json_pure choice childprocess ffi 


### Rackful
[Rackful](http://pieterb.github.com/Rackful/) is a library to build ReSTful web
services on top of [Rack](http://rack.rubyforge.org/doc/).

You might want to read the
[Rack interface specification](http://rack.rubyforge.org/doc/SPEC.html)
and [other Rack documentation]() as well. You will need a version 0.1.x of
rackful. It can be downloaded from: https://rubygems.org/gems/rackful.
version 0.2.x of rackful is NOT compatible with the EPIC-API.

    jruby -S gem install  rackful -v 0.1.4




Installation
------------
The EPIC API is tightly coupled the handle server which it connects to. It has
to be run as the same user as the handle server is running. The EPIC API is
installed as follows:

### EPIC API
create a directory and unzip the package in that directory (Use the same user as the
handle server is running under). An example would be:

    cd
    unzip EPIC_API in to $HOME/epic_v2_prod_<prefix>

or

   cd 
   mkdir git ; cd git
   git clone git://github.com/CatchPlus/EPIC-API-v2.git
   cd
   ln -s git/EPIC-API-v2 epic_v2_prod_<prefix>


The web service needs to know the location of your Handle System installation.
Create a symbolic link inside the Web Service top level directory called `hsj`,
pointing to `$HS_DISTRO_ROOT/lib`.

    cd epic_v2_prod_<prefix>
    ln -s <directory_handle_service>/hsj/lib hsj


Configuration
-------------

The web service comes preconfigured for HTTP Digest authentication.
You will need to create two configuration files for this to work, though:

### General configuration
The default installation expects some configuration information in file
`config.rb`. You will find a sample configuration file called
`config.rb.example` in the distribution. Copy or rename this file to `config.rb`
and edit it to your situation:

    cp -a config.rb.example config.rb
    $EDITOR config.rb

The config.rb has the connection details to the database for instance. It has
been developed against mysql. So that is what supported. The first line in
config.ru can have the port on which the epic server listens. It is in the
format of:

    #\ --port 9292 --server mizuno

The default installation expects some configuration information in file
`config.ru`. You will find a sample configuration file called
`config.ru.example` in the distribution. Copy or rename this file to
`config.ru` and edit it to your situation:

    cp -a config.ru.example config.ru
    $EDITOR config.ru


### User accounts
In the default configuration, account information is expected in file
`secrets/users.rb`. From the installation root, do the following:

    cd secrets/
    cp -a users.rb.example users.rb
    $EDITOR users.rb

The passwords are hashed in the field "digest". It is the MD5 checksum of
"<username>:EPIC:<password>".

For the communication with the handle service a key has to be present in the
`secrets` directory. It must have the format `300_0_NA_prefix`

an example is following:

    300_0_NA_prefix -> <handle_configuration_directory>/privkey.bin

### Apache 

The file /etc/httpd/conf.d/ssl.conf has the following addition.

    ProxyPass /v2/ http://localhost:9292/
    ProxyPassReverse /v2/ http://localhost:9292/
    ProxyPassReverseCookieDomain localhost:9922 <fully_qualified_hostname>
    ProxyPassReverseCookiePath / /v2/

Apache acts as a proxy. HTTPS traffic is routed to localhost port 9292. This 
is the port where the epic server v2 listens. So everything which starts with /v2/ is
routed/proxied to the EPIC service.

If Apache is used modify config.ru to have the correct url returned:

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


Running!
--------

At this point, you should be able to start the web service:

    rackup

By default, this will start a Webrick web server, listening to port 9292.

If you would like to use another web server, another port number, another
authentication method, then check out the Rack documentation, and start editing
the rackup configuration file `config.ru`. That files contains a lot of in-line
documentation that hopefully gets you started.

At this time a https request can be done to: `https://<fully_qualified_hostname>/v2/handles/`


