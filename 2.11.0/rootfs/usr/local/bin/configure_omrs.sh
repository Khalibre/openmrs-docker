#!/bin/bash
set -e

source /usr/local/bin/_omrs_common.sh

OMRS_WEBAPP_NAME=${OMRS_WEBAPP_NAME:-openmrs}

OMRS_DATA_DIR=${OMRS_HOME:-/opt/openmrs/data}
OMRS_MODULES_DIR="$OMRS_DATA_DIR/modules"
OMRS_OWA_DIR="$OMRS_DATA_DIR/owa"
OMRS_CONFIG_DIR="$OMRS_DATA_DIR/configuration"

OMRS_SERVER_PROPERTIES_FILE="$OMRS_HOME/$OMRS_WEBAPP_NAME-server.properties"
OMRS_RUNTIME_PROPERTIES_FILE="$OMRS_HOME/$OMRS_WEBAPP_NAME-runtime.properties"

function main {
    config_tomcat
    generate_omrs_config
}

function config_tomcat {
  local TOMCAT_DIR="$CATALINA_HOME"
  local TOMCAT_WEBAPPS_DIR="$TOMCAT_DIR/webapps"
  local TOMCAT_WORK_DIR="$TOMCAT_DIR/work"
  local TOMCAT_TEMP_DIR="$TOMCAT_DIR/temp"
  local TOMCAT_SETENV_FILE="$TOMCAT_DIR/bin/setenv.sh"

  local OMRS_DISTRO_DIR="$BASE_DIR/distribution"
  local OMRS_DISTRO_WEBAPPS="$OMRS_DISTRO_DIR/openmrs_webapps"
  local OMRS_DISTRO_MODULES="$OMRS_DISTRO_DIR/openmrs_modules"
  local OMRS_DISTRO_OWAS="$OMRS_DISTRO_DIR/openmrs_owas"
  local OMRS_DISTRO_CONFIG="$OMRS_DISTRO_DIR/openmrs_config"

  echo "[ENTRYPOINT] : Clearing out existing directories of any previous artifacts"

  rm -fR $TOMCAT_WEBAPPS_DIR;
  rm -fR $OMRS_MODULES_DIR;
  rm -fR $OMRS_OWA_DIR
  rm -fR $OMRS_CONFIG_DIR
  rm -fR $TOMCAT_WORK_DIR
  rm -fR $TOMCAT_TEMP_DIR
  mkdir $TOMCAT_TEMP_DIR

  echo "[ENTRYPOINT] : Loading artifacts into appropriate locations"

  # Copy files from mounted directory to PI_HOME
  if [ -d "${OMRS_MOUNT_DIR}/files" ] && [ "$(ls -A "${OMRS_MOUNT_DIR}/files")" ]; then
      echo ""
      echo "[ENTRYPOINT] : Copying files from ${OMRS_MOUNT_DIR}/files:"
      echo ""
      echo "[ENTRYPOINT] : ... into ${OMRS_DISTRO_DIR}."
      cp -r ${OMRS_MOUNT_DIR}/files/* ${OMRS_DISTRO_DIR}/
      echo ""
  else
      echo ""
      echo "[ENTRYPOINT] : The directory ${OMRS_MOUNT_DIR}/files does not exist or is empty. Copy any files to this directory to have them copied to ${OMRS_HOME} before openMRS starts."
      echo ""
  fi

  cp -r $OMRS_DISTRO_WEBAPPS $TOMCAT_WEBAPPS_DIR
  [ -d "$OMRS_DISTRO_MODULES" ] && cp -r $OMRS_DISTRO_MODULES $OMRS_MODULES_DIR
  [ -d "$OMRS_DISTRO_OWAS" ] && cp -r $OMRS_DISTRO_OWAS $OMRS_OWA_DIR
  [ -d "$OMRS_DISTRO_CONFIG" ] && cp -r $OMRS_DISTRO_CONFIG $OMRS_CONFIG_DIR

  echo "[ENTRYPOINT] : Writing out $TOMCAT_SETENV_FILE file"

  JAVA_OPTS="$OMRS_JAVA_SERVER_OPTS $OMRS_JAVA_MEMORY_OPTS"
  CATALINA_OPTS="-DOPENMRS_INSTALLATION_SCRIPT=$OMRS_SERVER_PROPERTIES_FILE -DOPENMRS_APPLICATION_DATA_DIRECTORY=$OMRS_DATA_DIR/"

  printf '%s\n' \
    "export JAVA_OPTS=\"${JAVA_OPTS}\"" \
    "export CATALINA_OPTS=\"${CATALINA_OPTS}\"" > $TOMCAT_SETENV_FILE

  # This command adds the following lines to /usr/local/tomcat/conf/server.xml:
  #   URIEncoding="UTF-8" relaxedPathChars="[]|" relaxedQueryChars="[]|{}^&#x5c;&#x60;&quot;&lt;&gt;"
  if ! grep -q "relaxedPathChars" $CATALINA_HOME/conf/server.xml; then
    sed -i '/Connector port="8080"/a URIEncoding="UTF-8" relaxedPathChars="[]|" relaxedQueryChars="[]|{}^&#x5c;&#x60;&quot;&lt;&gt;"' $CATALINA_HOME/conf/server.xml
  fi

  if [ -n "$OMRS_TOMCAT_CONFIG_SESSION_TIMEOUT" ]; then
    # Update the session timeout value in the XML file
    sed -i "s/<session-timeout>[0-9]\+<\/session-timeout>/<session-timeout>$OMRS_TOMCAT_CONFIG_SESSION_TIMEOUT<\/session-timeout>/" $CATALINA_HOME/conf/web.xml
    echo "[ENTRYPOINT] : Session timeout value updated to $OMRS_TOMCAT_CONFIG_SESSION_TIMEOUT minutes."
  fi

  if [ "$OMRS_TOMCAT_CONFIG_CORS_FILTER_ENABLED" == "true" ]; then
    echo "[ENTRYPOINT] : OMRS_TOMCAT_CONFIG_CORS_FILTER_ENABLED is set to true so CORS filter is enabled in web.xml"
    insert_cors_filter_to_web_xml
  fi

}

function generate_omrs_config {
  local config_file="$OMRS_SERVER_PROPERTIES_FILE"

  configure_database

  if check_file_exists "$config_file"; then
    echo "[ENTRYPOINT] : File '$config_file found. Backup and genetaring new one to replace it."
    cp "$config_file" "$config_file.bak"
  fi
  printf '%s\n' \
    "add_demo_data=${OMRS_CONFIG_ADD_DEMO_DATA}" \
    "admin_user_password=${OMRS_CONFIG_ADMIN_USER_PASSWORD}" \
    "application_data_directory=${OMRS_DATA_DIR}" \
    "auto_update_database=${OMRS_CONFIG_AUTO_UPDATE_DATABASE}" \
    "connection.driver_class=${OMRS_CONFIG_CONNECTION_DRIVER_CLASS}" \
    "create_database_username=${OMRS_CONFIG_CONNECTION_ROOT_USERNAME}" \
    "create_database_password=${OMRS_CONFIG_CONNECTION_ROOT_PASSWORD}" \
    "create_user_username=${OMRS_CONFIG_CONNECTION_ROOT_USERNAME}" \
    "create_user_password=${OMRS_CONFIG_CONNECTION_ROOT_PASSWORD}" \
    "connection.username=${OMRS_CONFIG_CONNECTION_USERNAME}" \
    "connection.password=${OMRS_CONFIG_CONNECTION_PASSWORD}" \
    "connection.url=${OMRS_CONFIG_CONNECTION_URL}" \
    "create_database_user=${OMRS_CONFIG_CREATE_DATABASE_USER}" \
    "create_tables=${OMRS_CONFIG_CREATE_TABLES}" \
    "has_current_openmrs_database=${OMRS_CONFIG_HAS_CURRENT_OPENMRS_DATABASE}" \
    "install_method=${OMRS_CONFIG_INSTALL_METHOD}" \
    "module_web_admin=${OMRS_CONFIG_MODULE_WEB_ADMIN}" \
    "module.allow_web_admin=${OMRS_CONFIG_MODULE_WEB_ADMIN}" > "$config_file"

  echo "[ENTRYPOINT] : OpenMRS configuration file created at: $config_file"
  echo "[ENTRYPOINT] : File $OMRS_RUNTIME_PROPERTIES_FILE will create copying with $OMRS_SERVER_PROPERTIES_FILE"
  cp $OMRS_SERVER_PROPERTIES_FILE $OMRS_RUNTIME_PROPERTIES_FILE
}

function configure_database {
  local OMRS_CONFIG_DATABASE="${OMRS_CONFIG_DATABASE:-mysql}"
  local OMRS_CONFIG_CONNECTION_SERVER="${OMRS_CONFIG_CONNECTION_SERVER:-localhost}"
  local OMRS_CONFIG_CONNECTION_DATABASE="${OMRS_CONFIG_CONNECTION_DATABASE:-openmrs}"

  if [[ -z $OMRS_CONFIG_DATABASE || "$OMRS_CONFIG_DATABASE" == "mysql" || "$OMRS_CONFIG_DATABASE" == "mariadb" ]]; then
    OMRS_CONFIG_JDBC_URL_PROTOCOL=mysql
    OMRS_CONFIG_CONNECTION_DRIVER_CLASS="${OMRS_CONFIG_CONNECTION_DRIVER_CLASS:-com.mysql.jdbc.Driver}"
    OMRS_CONFIG_CONNECTION_PORT="${OMRS_CONFIG_CONNECTION_PORT:-3306}"
    OMRS_CONFIG_CONNECTION_ARGS="${OMRS_CONFIG_CONNECTION_ARGS:-?autoReconnect=true&sessionVariables=default_storage_engine=InnoDB&useUnicode=true&characterEncoding=UTF-8}"
  elif [[ "$OMRS_CONFIG_DATABASE" == "postgresql" ]]; then
    OMRS_CONFIG_JDBC_URL_PROTOCOL=postgresql
    OMRS_CONFIG_CONNECTION_DRIVER_CLASS="${OMRS_CONFIG_CONNECTION_DRIVER_CLASS:-org.postgresql.Driver}"
    OMRS_CONFIG_CONNECTION_PORT="${OMRS_CONFIG_CONNECTION_PORT:-5432}"
  else
    echo "[ENTRYPOINT] : Unknown database type $OMRS_CONFIG_DATABASE. Using properties for MySQL"
    OMRS_CONFIG_JDBC_URL_PROTOCOL=mysql
    OMRS_CONFIG_CONNECTION_DRIVER_CLASS="${OMRS_CONFIG_CONNECTION_DRIVER_CLASS:-com.mysql.jdbc.Driver}"
    OMRS_CONFIG_CONNECTION_PORT="${OMRS_CONFIG_CONNECTION_PORT:-3306}"
    OMRS_CONFIG_CONNECTION_ARGS="${OMRS_CONFIG_CONNECTION_ARGS:-?autoReconnect=true&sessionVariables=default_storage_engine=InnoDB&useUnicode=true&characterEncoding=UTF-8}"
  fi

  OMRS_CONFIG_CONNECTION_URL="${OMRS_CONFIG_CONNECTION_URL:-jdbc:${OMRS_CONFIG_JDBC_URL_PROTOCOL}://${OMRS_CONFIG_CONNECTION_SERVER}:${OMRS_CONFIG_CONNECTION_PORT}/${OMRS_CONFIG_CONNECTION_DATABASE}${OMRS_CONFIG_CONNECTION_ARGS}${OMRS_CONFIG_CONNECTION_EXTRA_ARGS}}"
}

main
