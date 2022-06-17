profilecloner
=============
~~~
JBoss WildFly / JBoss EAP 6.1+ Profile (and more) Cloner - by Tom Fonteyne
Usage:
 java -cp $JBOSS_HOME/bin/client/jboss-cli-client.jar:profilecloner.jar
    org.jboss.tfonteyne.profilecloner.Main
    --controller=<host> --port=<number> --username=<user> --password=<password>
    --file=<name> --add-deployments=<true|false>
    /from=value destinationvalue [/from=value destinationvalue] ....

Options:
  --controller=<host> | -c <host>       : Defaults to the setting in jboss-cli.xml if you have one,
  --port=<port>                           or localhost and 9999 (wildfly:9990)
  --username=<user> | -u <user>         : When not set, $local authentication is attempted
  --password=<password> | -p <password>
  --file=<name> | -f <name>             : The resulting CLI commands will be written to the file
                                          If not set, they are output on the console
  --add-deployments=<true|false> | -ad  : By default cloning a server-group will skip the deployments
                                          If you first copy the content folder and clone the deployments,
                                          you can enable this

Examples for "/from=value destinationvalue":
  Domain mode:
    /socket-binding-group=full-ha-sockets full-ha-sockets-copy
    /profile=full-ha full-ha-copy
    /profile=full-ha/subsystem=web web

  Standalone server:
    /subsystem=security security
    profile
   The latter being a shortcut to clone all subsystems in individual batches

Each set will generate a batch/run-batch. It is recommended to clone the profile last
The names from/to can be equal if you want to execute the script on a different controller.

 Secure connections need:
    -Djavax.net.ssl.trustStore=/path/to/store.jks -Djavax.net.ssl.trustStorePassword=password

Note that EAP 6.0.x is **not** supported.
The cloner will break on the "module-option" entries inside "login-module" sections.
Workaround is to remove those manually before cloning.
The file "jboss-cli-client.jar" does also not exist in those versions,
instead take a look at jconsole.sh for the equivalent set of files you will need.
As EAP 6.0.x is very old now, you really should be upgrading anyhow.
~~~
Exporting your WildFly / JBoss EAP configuration to a **CLI script** is something you are going to need one day or another. No worries, the project **Profile Cloner** comes to rescue! (Updated to work with WildFly **26 and Java 11**)

## To get ProfileCloner!
For this purpose, I have created my own fork of it: https://github.com/fmarchioni/profilecloner

Firstly, clone or download a copy of the project on your local drive:
```shell
git clone https://github.com/fmarchioni/profilecloner
```
Next, move the the profilecloner folder:
```shell
cd profilecloner
```
Then, build the project to generate the profilecloner.jar file:
```shell
mvn install
```
Finally, set your **JBOSS_HOME** so that the launch script can pickup the jboss-cli-client.jar:
```shell
export JBOSS_HOME=/opt/jboss/
```
## Generating the CLI script from a standalone.xml
We are now ready to reverse engineer the standalone.xml configuration from a WildFly server.
Firstly, start WildFly server:
```
./standalone.sh
```
We will assume that there’s an available management user with credentials (admin/admin). To learn more about User Management check this article: How to Add an User in WildFly

Next, execute the profilecloner.sh script passing as argument the output script name (save-script.cli) the controller host address (localhost), the user credentials and the profile to clone. You can use the markerplace “profile” to clone the default server profile:
```cmd
>profilecloner.bat  -f  save-script.cli  --controller=localhost --username=admin --password=123456 profile
```
We are done! Check the save-script.cli to see your XML configuration as a set of CLI batch scripts:
```cli
batch
/subsystem="logging":add()
/subsystem="logging"/console-handler="CONSOLE":add(level="INFO",name="CONSOLE",named-formatter="COLOR-PATTERN")
/subsystem="logging"/logger="com.arjuna":add(category="com.arjuna",level="WARN")
/subsystem="logging"/logger="io.jaegertracing.Configuration":add(category="io.jaegertracing.Configuration",level="WARN")
/subsystem="logging"/logger="org.jboss.as.config":add(category="org.jboss.as.config",level="DEBUG")
/subsystem="logging"/logger="sun.rmi":add(category="sun.rmi",level="WARN")
/subsystem="logging"/pattern-formatter="PATTERN":add(pattern="%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n")
/subsystem="logging"/pattern-formatter="COLOR-PATTERN":add(pattern="%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n")
/subsystem="logging"/periodic-rotating-file-handler="FILE":add(append="true",autoflush="true",file={"relative-to" => "jboss.server.log.dir","path" => "server.log"},name="FILE",named-formatter="PATTERN",suffix=".yyyy-MM-dd")
/subsystem="logging"/root-logger="ROOT":add(handlers=["CONSOLE","FILE"],level="INFO")
run-batch
(ommitted...)
```
The awesome part of it is that you can create copy of single parts of your profile. For example here is how to reverse engineer the infinispan subsystem you can run:
```shell
./profilecloner.sh -f save-script.cli  --controller=localhost --username=admin --password=admin /profile=full-ha full-ha
```
Now your **save-script.cli** contains all the CLI configuration for your profile:
```cli
batch
/profile="full-ha":add()
/profile="full-ha"/subsystem="logging":add()
/profile="full-ha"/subsystem="logging"/logger="com.arjuna":add(category="com.arjuna",level="WARN")
/profile="full-ha"/subsystem="logging"/logger="io.jaegertracing.Configuration":add(category="io.jaegertracing.Configuration",level="WARN")
/profile="full-ha"/subsystem="logging"/logger="org.jboss.as.config":add(category="org.jboss.as.config",level="DEBUG")
/profile="full-ha"/subsystem="logging"/logger="sun.rmi":add(category="sun.rmi",level="WARN")
/profile="full-ha"/subsystem="logging"/pattern-formatter="PATTERN":add(pattern="%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n")
/profile="full-ha"/subsystem="logging"/pattern-formatter="COLOR-PATTERN":add(pattern="%K{level}%d{HH:mm:ss,SSS} %-5p [%c] (%t) %s%e%n")
```
