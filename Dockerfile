# https://hub.docker.com/r/jenkins/jenkins/tags/
FROM jenkins/jenkins:lts-alpine

USER root

# Sets time
RUN ln -fs /usr/share/zoneinfo/Africa/Lagos /etc/localtime
RUN date

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh gettext make docker

# Allow the jenkins user to run docker
RUN adduser jenkins docker

# Drop back to the regular jenkins user
USER jenkins

# Set Log
COPY log.properties /usr/share/jenkins/ref/log.properties

# 1. Disable Jenkins setup Wizard UI. The initial user and password will be supplied by Terraform via ENV vars during infrastructure creation
# 2. Set Java DNS TTL to 60 seconds
# http://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/java-dg-jvm-ttl.html
# http://docs.oracle.com/javase/7/docs/technotes/guides/net/properties.html
# https://aws.amazon.com/articles/4035
# https://stackoverflow.com/questions/29579589/whats-the-recommended-way-to-set-networkaddress-cache-ttl-in-elastic-beanstalk
ENV JAVA_OPTS="-Dhudson.tasks.MailSender.SEND_TO_UNKNOWN_USERS=true -Dhudson.tasks.MailSender.SEND_TO_USERS_WITHOUT_READ=true -Dorg.apache.commons.jelly.tags.fmt.timeZone=Africa/Lagos -Djava.util.logging.config.file=/usr/share/jenkins/ref/log.properties -Djenkins.install.runSetupWizard=false -Dhudson.DNSMultiCast.disabled=true -Djava.awt.headless=true -Dsun.net.inetaddr.ttl=60 -Duser.timezone=PST -Dorg.jenkinsci.plugins.gitclient.Git.timeOut=60"

# Preinstall plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Setup Jenkins initial admin user, security mode (Matrix), and the number of job executors
# Many other Jenkins configurations could be done from the Groovy script
COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/

# Configure `Amazon EC2` plugin to start slaves on demand
COPY init-ec2.groovy /usr/share/jenkins/ref/init.groovy.d/

EXPOSE 8080
