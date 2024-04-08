#!/bin/bash

function main {
    . configure_omrs.sh
    start_omrs
}

function start_omrs {

    set +e

    start_omrs.sh &

    START_OMRS_PID=$!

    echo "${START_OMRS_PID}" > "${OMRS_PID}"

    # Trigger first filter to start data importation
    sleep 15
    curl -sL http://localhost:8080/$OMRS_WEBAPP_NAME/ > /dev/null
    sleep 15

    wait ${START_OMRS_PID}
}

main
