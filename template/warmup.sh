#!/bin/sh

if [ -n "$WARM_REQ" ];
then 
    echo "Waiting until $APP_DIR App is ready and Warm it up"
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/warmup)" != "200" ]]; 
        do sleep 1;
    done
else
    echo "Waiting until $APP_DIR App is ready without Warmup"
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/ping)" != "200" ]]; 
        do sleep 1;
    done
fi