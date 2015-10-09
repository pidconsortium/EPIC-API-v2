#!/bin/bash
#
# Variables used by Eclipse-External Tool-Configuration
# JRE_HOME
# RUBY_BIN
# PATH
# TMP_FOLDER

# Java Options for Debugging JRUBY-Running behaviour

# Timing
# export JAVA_OPTS="-Djruby.debug.loadService.timing=true"
# Loaded jars
# export JAVA_OPTS="-Djruby.debug.loadService=true"

# Check if Eclipse's External Tool Configuration is configured completely 
echo ${JRE_HOME?Error \$JRE_HOME is not defined. Check External-Tool Config}
echo ${JRUBY_BIN?Error \$JRUBY_BIN is not defined. Check External-Tool Config}
echo ${PATH?Error \$PATH is not defined. Check External-Tool Config}
echo ${TMP_FOLDER?Error \$TMP_FOLDER is not defined. Check External-Tool Config}

# Echo Environment-Information
echo "Welcome to EPIC-API-v2 on Eclipse"
echo "JRE_HOME set to: "$JRE_HOME
echo "JRUBY_BIN set to: "$JRUBY_BIN
echo "TMP_FOLDER set to: "$TMP_FOLDER

# Setup environment variables
export JAVA_ROOT=$JRE_HOME
export JAVA_HOME=$JRE_HOME
export JAVA_BINDIR=$JRE_HOME/bin
export JRUBY_OPTS="--1.9"
export PATH=$JRUBY_BIN:$PATH
unset JDK_HOME
unset SDK_HOME


# Check if EPIC-API-v2 is already running and present options
if [ -f $TMP_FOLDER/epic_standalone.pid ]
then
    echo -e  "\n----- PID-File of EPIC-API-v2 was found --- \n"
    echo -e "Select one option (1,2,3):\n"
    echo -e "Restart server        (1)"
    echo -e "Kill exiting instance (2)"
    echo -e "Cancel                (3)"
    read choice
    if (( "$choice" == "1" )) || (( "choice" == "2" ))
    then
    	echo "Terminating Server..."
    	kill -9 `cat $TMP_FOLDER/epic_standalone.pid` 2> /dev/null
    	rm $TMP_FOLDER/epic_standalone.pid 2> /dev/null
		rm $TMP_FOLDER/epic_log.txt 2> /dev/null
    fi
    if (( "$choice" == "2" )) || (( "$choice" == "3" ))
    then
    	echo "Exiting..."
    	exit
    fi
    if [[ "$choice" != [1-3] ]];
    then
    	echo "Invalid Input. Exiting..."
    	exit
    fi
fi
# Show Version-Numbers
java -version
$JRUBY_BIN/jruby --version
$JRUBY_BIN/rackup &

# Write PID-File
echo $! > $TMP_FOLDER/epic_standalone.pid
