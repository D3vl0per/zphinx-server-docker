#!/bin/ash
set -e

ORACLE_PATH=/usr/local/bin/oracle
DEFAULT_LT_STORE_PATH=/etc/ssl/sphinx
DEFAULT_LT_SIG_KEY_BASE=ltsig
DOCKER_MOVE_KEYS_PATH=/tmp/keys

if [ "$1" = "init" ]; then
    exec $ORACLE_PATH init & sleep 1 && exit 0
elif [ "$1" = "docker-init" ]; then
    if [ ! -f "$DOCKER_MOVE_KEYS_PATH/$DEFAULT_LT_SIG_KEY_BASE.key" ]; then
        echo "Docker init"
        exec $ORACLE_PATH init & sleep 1 \
        && cp $DEFAULT_LT_STORE_PATH/$DEFAULT_LT_SIG_KEY_BASE.* $DOCKER_MOVE_KEYS_PATH \
        && base64 $DOCKER_MOVE_KEYS_PATH/$DEFAULT_LT_SIG_KEY_BASE.key.pub > $DOCKER_MOVE_KEYS_PATH/$DEFAULT_LT_SIG_KEY_BASE.key.pub.base64
    else
        echo "Keys already exist, please delete them if you want to regenerate or remove the docker-init command"
    fi
else
    exec $ORACLE_PATH "$@"
fi