
rem  set "JBOSS_HOME=c:\path\to\jboss"

java -cp %JBOSS_HOME%\bin\client\jboss-cli-client.jar;.\target\profilecloner.jar org.jboss.tfonteyne.profilecloner.Main %*
