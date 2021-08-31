# dockerfile to build image for JBoss EAP 7.2

# start from centos
FROM centos

# file author / maintainer
MAINTAINER "FirstName LastName" "emailaddress@gmail.com"

# update OS
RUN yum -y update && \
  yum -y install sudo openssh-clients telnet unzip java-11-openjdk-devel && \
  yum clean all

# enabling sudo group
# enabling sudo over ssh
RUN echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
  sed -i 's/.*requiretty$/Defaults !requiretty/' /etc/sudoers

# add a user for the application, with sudo permissions
RUN useradd -m jboss ; echo jboss: | chpasswd ; usermod -a -G wheel jboss

# create workdir
ARG SDG_BASEDIR=/opt/rh
ENV SDG_BASEDIR $SDG_BASEDIR
#ENV PROP_DIR "/conf"
RUN mkdir -p $SDG_BASEDIR


 
WORKDIR $SDG_BASEDIR

# install JBoss EAP 7.2.0
ARG JBOSS_URL=jboss-eap-7.2.0.zip
ADD $JBOSS_URL /tmp/jboss-eap.zip
RUN unzip /tmp/jboss-eap.zip && rm /tmp/jboss-eap.zip

# set environment
ARG JBOSS_HOME=$SDG_BASEDIR/jboss-eap-7.2
ENV JBOSS_HOME $JBOSS_HOME

# create JBoss console user
RUN $JBOSS_HOME/bin/add-user.sh admin admin@2021 --silent
# configure JBoss
RUN echo "JAVA_OPTS=\"\$JAVA_OPTS -Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0\"" >> $JBOSS_HOME/bin/standalone.conf

# add Keycloak submodule
ARG KC_URL=https://github.com/keycloak/keycloak/releases/download/13.0.1/keycloak-oidc-wildfly-adapter-13.0.1.zip
ADD $KC_URL /tmp/kc-adapter.zip
ADD enable-property-replacement.cli $SDG_BASEDIR
RUN unzip /tmp/kc-adapter.zip -d $JBOSS_HOME && \
  rm /tmp/kc-adapter.zip && \
  $JBOSS_HOME/bin/jboss-cli.sh -Dserver.config=standalone-full-ha.xml --file=$JBOSS_HOME/bin/adapter-elytron-install-offline.cli && \
  $JBOSS_HOME/bin/jboss-cli.sh -Dserver.config=standalone-full-ha.xml --file=$SDG_BASEDIR/enable-property-replacement.cli && \
  $JBOSS_HOME/bin/jboss-cli.sh -Dserver.config=standalone.xml --file=$JBOSS_HOME/bin/adapter-elytron-install-offline.cli && \
  $JBOSS_HOME/bin/jboss-cli.sh -Dserver.config=standalone.xml --file=$SDG_BASEDIR/enable-property-replacement.cli && \
  rm -rf $JBOSS_HOME/standalone/configuration/standalone_xml_history/current
#  touch $SDG_BASEDIR/system.properties

# set permission folder
RUN chmod -R 777 $SDG_BASEDIR

#VOLUME $SDG_BASEDIR/system.properties

# JBoss ports
EXPOSE 8080 9990 9999

# start JBoss
ENTRYPOINT $JBOSS_HOME/bin/standalone.sh -c standalone.xml -P /opt/rh/system.properties

USER jboss
CMD /bin/bash
