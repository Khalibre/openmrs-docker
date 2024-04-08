FROM ubuntu:20.04 AS builder

ARG OMRS_VERSION=2.11.0
ENV TINI_VERSION v0.19.0
ENV DISTRO_DIR /app/distribution

RUN apt-get update && apt-get install -y wget unzip gnupg2
RUN mkdir -p ${DISTRO_DIR}/openmrs_webapps
RUN wget -L https://sourceforge.net/projects/openmrs/files/releases/OpenMRS_Reference_Application_${OMRS_VERSION}/openmrs.war -O ${DISTRO_DIR}/openmrs_webapps/openmrs.war
RUN wget -L https://sourceforge.net/projects/openmrs/files/releases/OpenMRS_Reference_Application_${OMRS_VERSION}/referenceapplication-addons-${OMRS_VERSION}.zip -O /tmp/referenceapplication-addons.zip \
  && unzip /tmp/referenceapplication-addons.zip -d /tmp/ \
  && mv /tmp/referenceapplication-package-${OMRS_VERSION}/modules ${DISTRO_DIR}/openmrs_modules \
  && mv /tmp/referenceapplication-package-${OMRS_VERSION}/owa ${DISTRO_DIR}/openmrs_owas

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
  && gpg --batch --verify /tini.asc /tini
RUN chmod +x /tini

FROM tomcat:7.0.109-jdk8-openjdk-buster

ENV OMRS_HOME "/opt/openmrs"

# All environment variables that are available to configure on this container are listed here
# for clarity.  These list the variables supported, and the default values if not overridden

# These environment variables are appended to configure the Tomcat JAVA_OPTS
ENV OMRS_JAVA_MEMORY_OPTS="-Xmx2048m -Xms1024m -XX:NewSize=128m"
ENV OMRS_JAVA_SERVER_OPTS="-Dfile.encoding=UTF-8 -server -Djava.security.egd=file:/dev/./urandom -Djava.awt.headless=true -Djava.awt.headlesslib=true"

# These environment variables are used to create the openmrs-server.properties file, which controls how OpenMRS initializes
ENV OMRS_CONFIG_ADD_DEMO_DATA="false"
ENV OMRS_CONFIG_ADMIN_USER_PASSWORD="Admin123"
ENV OMRS_CONFIG_AUTO_UPDATE_DATABASE="true"
# valid values are mysql and postgres
ENV OMRS_CONFIG_CONNECTION_TYPE="mysql"
ENV OMRS_CONFIG_CONNECTION_USERNAME="openmrs"
ENV OMRS_CONFIG_CONNECTION_PASSWORD="openmrs"
ENV OMRS_CONFIG_CONNECTION_ROOT_USERNAME="root"
ENV OMRS_CONFIG_CONNECTION_ROOT_PASSWORD="root"
ENV OMRS_CONFIG_CONNECTION_SERVER="localhost"
ENV OMRS_CONFIG_CONNECTION_PORT="3306"
ENV OMRS_CONFIG_CONNECTION_NAME="openmrs"
ENV OMRS_CONFIG_CREATE_DATABASE_USER="false"
ENV OMRS_CONFIG_CREATE_TABLES="false"
ENV OMRS_CONFIG_HAS_CURRENT_OPENMRS_DATABASE="true"
ENV OMRS_CONFIG_INSTALL_METHOD="auto"
ENV OMRS_CONFIG_MODULE_WEB_ADMIN="true"

# These environment variables are meant to enable developer settings
ENV JPDA_ADDRESS=0.0.0.0:8000
ENV OMRS_PID="${OMRS_HOME}/omrs.pid"
ENV OMRS_TOMCAT_CONFIG_CORS_FILTER_ENABLED="true"
ENV OMRS_TOMCAT_JPDA_ENABLED="false"

# Additional environment variables as needed. This should match the name of the distribution supplied OpenMRS war file
ENV OMRS_WEBAPP_NAME="openmrs"

RUN adduser --disabled-password --home /opt/openmrs openmrs --uid 1000 && \
  addgroup openmrs openmrs && \
  usermod -g 1000 openmrs && \
  mkdir -p ${OMRS_HOME} ${OMRS_HOME}/data && \
  chown -R openmrs:openmrs /usr/local/tomcat && \
  chown -R openmrs:openmrs ${OMRS_HOME}

COPY --chown=openmrs:openmrs --from=builder /app ${OMRS_HOME}
COPY --from=builder /tini /usr/local/bin/tini

COPY rootfs /

USER openmrs

VOLUME [ "${OMRS_HOME}/data", "${OMRS_HOME}/distribution" ]

WORKDIR ${OMRS_HOME}

ENTRYPOINT [ "tini", "--", "/usr/local/bin/omrs_entrypoint.sh" ]
