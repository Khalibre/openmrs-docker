#!/bin/bash

function main {
    /usr/local/bin/wait-for-it.sh --timeout=3600 ${OMRS_CONFIG_CONNECTION_SERVER}:${OMRS_CONFIG_CONNECTION_PORT}

    echo ""
    echo "[ENTRYPOINT] : Starting ${OMRS_WEBAPP_NAME}. To stop the container with CTRL-C, run this container with the option \"-it\"."
    echo ""


    if [ "${OMRS_TOMCAT_JPDA_ENABLED}" == "true" ]
    then
        exec "${CATALINA_HOME}"/bin/catalina.sh jpda run
    else
        exec "${CATALINA_HOME}"/bin/catalina.sh run
    fi

}

main
