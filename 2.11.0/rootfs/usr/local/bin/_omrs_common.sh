#!/bin/bash

check_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        return 0
    else
        return 1
    fi
}

insert_cors_filter_to_web_xml() {
    local web_xml="/usr/local/tomcat/conf/web.xml"

    if check_file_exists "$web_xml" && grep -q "CorsFilter" "$web_xml"; then
        echo "[ENTRYPOINT] CORS filter block already added to '$web_xml'. Skipping."
    else
        local filter_block="<filter>\n\
            <filter-name>CorsFilter</filter-name>\n\
            <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>\n\
            <init-param>\n\
                <param-name>cors.allowed.origins</param-name>\n\
                <param-value>${OMRS_TOMCAT_CONFIG_CORS_FILTER_ALLOWED_ORIGINS:-*}</param-value>\n\
            </init-param>\n\
            <init-param>\n\
                <param-name>cors.allowed.methods</param-name>\n\
                <param-value>GET,POST,HEAD,OPTIONS,PUT</param-value>\n\
            </init-param>\n\
            <init-param>\n\
                <param-name>cors.allowed.headers</param-name>\n\
                <param-value>Content-Type,X-Requested-With,accept,Origin,Access-Control-Request-Method,Access-Control-Request-Headers</param-value>\n\
            </init-param>\n\
            <init-param>\n\
                <param-name>cors.exposed.headers</param-name>\n\
                <param-value>Access-Control-Allow-Origin,Access-Control-Allow-Credentials</param-value>\n\
            </init-param>\n\
            <init-param>\n\
                <param-name>cors.support.credentials</param-name>\n\
                <param-value>true</param-value>\n\
            </init-param>\n\
        </filter>\n\
        <filter-mapping>\n\
            <filter-name>CorsFilter</filter-name>\n\
            <url-pattern>*.htm</url-pattern>\n\
        </filter-mapping>\n\
        <filter-mapping>\n\
            <filter-name>CorsFilter</filter-name>\n\
            <url-pattern>*.page</url-pattern>\n\
        </filter-mapping>"

        if check_file_exists "$web_xml"; then
            sed -i "/<\/web-app>$/i $filter_block" "$web_xml"
        else
            echo "[ENTRYPOINT] File '$web_xml' not found. Skipping CORS filter configuration."
        fi
    fi
}
