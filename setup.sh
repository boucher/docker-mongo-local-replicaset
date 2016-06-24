#!/bin/bash
set -e

USERNAME=${USERNAME:=dev}
PASSWORD=${PASSWORD:=dev}

NEEDS_CONFIG=1
if [ "$(ls -A /data/db1)" ]; then
     unset -v NEEDS_CONFIG
fi

if [ $NEEDS_CONFIG ]; then
    mongod --smallfiles --noprealloc --dbpath /data/db1 &
    MONGO_PID=$!

    sleep 5
    echo "CREATING USER ACCOUNT"
    mongo admin --eval "db.createUser({ user: '$USERNAME', pwd: '$PASSWORD', roles: ['root', 'restore', 'readWriteAnyDatabase', 'dbAdminAnyDatabase'] })"

    echo "KILLING MONGO"
    kill $MONGO_PID
    sleep 5
fi

echo "WRITING KEYFILE"

openssl rand -base64 741 > /var/mongo_keyfile
chown mongodb /var/mongo_keyfile
chmod 600 /var/mongo_keyfile

echo "STARTING CLUSTER"

mongod --port 27001 --smallfiles --noprealloc --dbpath /data/db1 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
mongod --port 27002 --smallfiles --noprealloc --dbpath /data/db2 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
mongod --port 27003 --smallfiles --noprealloc --dbpath /data/db3 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &

if [ $NEEDS_CONFIG ]; then
    sleep 10
    echo "CONFIGURING REPLICA SET"
    CONFIG='{ _id: "rs0", members: [{_id: 0, host: "localhost:27001", priority: 2 }, { _id: 1, host: "localhost:27002" }, { _id: 2, host: "localhost:27003" } ]}'
    mongo admin --port 27001 -u $USERNAME -p $PASSWORD --eval "db.runCommand({ replSetInitiate: $CONFIG })"
fi

wait
