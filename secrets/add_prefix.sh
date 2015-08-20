#!/bin/bash
# 
# this procedure creates the needed info to add a user to the users.rb
# it uses pwgen from the package pwgen
#

# TODO: test for CLI params.
# Usage: $0 <prefix> <YOUR_REALM> 
# The prefix is a number.
# The default realm is 'EPIC'. If you fill in $2 it uses that for the realm.

# set the realm
REALM='EPIC'
if [ -n "$2" ]
then
   REALM=$2
fi

# generate a password
PASSWORD=$(pwgen -s 10 1)
#PASSWORD='CL5tDcdXoS'

# create the digest
DIGEST=$( echo -n "$1:$REALM:$PASSWORD" | md5sum )
DIGEST=${DIGEST:0:32}

# generate the strings for the users.rb
cat <<EOT
Please add the following to users.rb:

    '$1' => {
      :digest       => '$DIGEST', # $PASSWORD
      :handle       => '0.NA/$1',
      :index        => 300,
      #:index_create => 200,
      #:keycipher => 'YOUR_PASSPHRASE'
      #:secret => 'YOUR_PASSPHRASE',
      #:institute => 'YOUR_INSTITUTE'    # optional institute code which can be included into the handles
    },

EOT

