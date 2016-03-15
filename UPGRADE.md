# Upgrading

The following document describes how to upgrade the handle software and ePIC API.

We start with a system with: hsj 7 and ePIC API v2.3.
We end up with a system with: hsj 8 and ePIC API v2.5.1.


The plan is:

1. create backups as the user who runs the handle software and the ePIC API. An example is:

        # su - <handle_user>
        $ cp -a .handle .handle.org
        $ cp -a <directory_with_handle_config> <directory_with_handle_config.org>
        $ cp -a <directory_with_epic_installation> <directory_with_epic_installation.org>

2. stop the ePIC api as user "root".
Use your own procedures to stop the ePIC API. An example is:

        # service epic status epic_v2_test_prod
        # service epic stop epic_v2_test_prod
        # service epic status epic_v2_test_prod
        # service epic status


3. stop the handle server as user "root".
Use your own procedures to stop the handle server. An example is:

        # service hdl status surfsara_841
        # service hdl stop surfsara_841
        # service hdl status surfsara_841
        # service hdl status


4. install the handle software as the user "root".
Untar the handle software in the place of your choosing. An example is:

        # cd /opt
        # tar -tvzf /tmp/hsj-8.1.0.tgz
        # tar -xvzf /tmp/hsj-8.1.0.tgz .
        # ls -l
        # chown -R root:root  /opt/hsj-8.1.0


5. make sure the handle software can use a mysql/MariaDB. Link the mysql connector jar as the user "root". An example is:

        # cd /opt/hsj-8.1.0/lib
        # ln -s /usr/share/java/mysql-connector-java.jar 


6. install the new ePIC api as the user who runs the handle software and the ePIC API. Use git commands or whatever you like to update the installation of the ePIC API.
Perform an update in ```<directory_with_epic_installation>```.

7. update the link to hsj library files as the user who runs the handle software and the ePIC API.
An example is:

        # su - <handle_user>
        $ cd <directory_with_epic_installation>
        $ ls -l hsj
        $ rm hsj
        $ ln -s /opt/hsj-8.1.0/lib hsj


7. modify the handle config as the user "root" to make sure the new handle version is used. An example is:

        # cd /etc/hdl
        # vi handle1_surfsara_841.conf
        # hdlBinDir=/opt/hsj-8.1.0/bin


8. modify your handle startup procedure as the user "root" for startup. 
Add the export of parameter ```HANDLE_SVR=<directory_with_handle_config>```in start of handle server. This can be used in a reverse lookup servlet.

9. modify your handle startup procedure as the user "root" for shutdown. 
Modify the stop command to delete a file ```<directory_with_handle_config>/delete_this_to_stop_server```. This will nicely stop the server.

10. modify ```<directory_with_handle_config>/config.dct``` for the new version of handle server as the user who runs the handle software and the ePIC API.
The release notes state what to change. From the release notes: "bind_address", "backlog", and "max_handlers", which were previously required, can now be omitted and will be given sensible defaults. More info is in the release notes.

11. create a new directory for java servlets as the user who runs the handle software and the ePIC API.
An example is as follows:

        # su - <handle_user>
        $ cd <directory_with_handle_config>
        $ mkdir webapps


12. optionally copy the administrative servlet to the java servlet directory as the user who runs the handle software and the ePIC API.
An example is as follows:

        # su - <handle_user>
        $ cd <directory_with_handle_config>
        $ cp admin.war webapps


13. start the handle server as user "root".
Use your own procedures to start the handle server. An example is:

        # service hdl status surfsara_841
        # service hdl start surfsara_841
        # service hdl status surfsara_841


14. update the ePIC api config as the user who runs the handle software and the ePIC API.
The following files need to be checked and updated:

        $ diff <directory_with_epic_installation>/config.rb <directory_with_epic_installation>/config.rb.example
        $ diff <directory_with_epic_installation>/config.ru <directory_with_epic_installation>/config.ru.example


15. modify your epic startup procedure as the user "root" for startup. 

16. start the ePIC api as user "root".
Use your own procedures to start the ePIC API. An example is:

        # service epic status epic_v2_test_prod
        # service epic start epic_v2_test_prod
        # service epic status epic_v2_test_prod

17. test the upgrade. Use your own procedures to test the upgrade.

18. check your logfiles for errors and messages.

DONE!!!



Replace the default certificate

The Handle server delivers a certificate taken from the serverCertificate.pem file in the instance directory.
To replace this with a proper certificate, do the following (based on a CentOS installation):

Convert your certificate to serverCertificate.pem:

        $ openssl x509 -in /etc/pki/tls/certs/<your .crt> -out serverCertificate.pem -outform pem

Convert certificate private key to pkcs8 format:

        $ openssl pkcs8 -in /etc/pki/tls/private/<your key file> -out serverCertificatePrivateKey.pem -inform pem -nocrypt -topk8

Convert to Handle binary key format using hdl-convert-key:

        $ ../hsj-8.1.0/bin/hdl-convert-key serverCertificatePrivateKey.pem serverCertificatePrivateKey.bin


