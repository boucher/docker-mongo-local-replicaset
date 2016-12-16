#!/bin/bash
set -e

USERNAME=${USERNAME:=dev}
PASSWORD=${PASSWORD:=dev}


function waitForMongo {
    port=$1
    user=$2
    pass=$3
    n=0
    until [ $n -ge 20 ]
    do
        if [ -z "$user" ]; then
            mongo admin --quiet --port $port --eval "db" && break
        else
            echo "trying: $port $user $pass"
            mongo admin --quiet --port $port -u $user -p $pass --eval "db" && break
        fi
        n=$[$n+1]
        sleep 2
    done
}

if [ ! "$(ls -A /data/db1)" ]; then
    mkdir /data/db1
    mkdir /data/db2
    mkdir /data/db3

    mongod --smallfiles --dbpath /data/db1 &
    MONGO_PID=$!

    waitForMongo 27017

    echo "CREATING USER ACCOUNT"
    mongo admin --eval "db.createUser({ user: '$USERNAME', pwd: '$PASSWORD', roles: ['root', 'restore', 'readWriteAnyDatabase', 'dbAdminAnyDatabase'] })"

    echo "KILLING MONGO"
    kill $MONGO_PID
    wait $MONGO_PID
fi

echo "WRITING KEYFILE"

openssl rand -base64 741 > /var/mongo_keyfile
chown mongodb /var/mongo_keyfile
chmod 600 /var/mongo_keyfile

echo "STARTING CLUSTER"

mongod --port 27003 --smallfiles --dbpath /data/db3 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
DB3_PID=$!
mongod --port 27002 --smallfiles --dbpath /data/db2 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
DB2_PID=$!
mongod --port 27001 --smallfiles --dbpath /data/db1 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
DB1_PID=$!

waitForMongo 27001 $USERNAME $PASSWORD
waitForMongo 27002
waitForMongo 27003

echo "CONFIGURING REPLICA SET: $HOSTNAME"
CONFIG="{ _id: 'rs0', members: [{_id: 0, host: '$HOSTNAME:27001', priority: 2 }, { _id: 1, host: '$HOSTNAME:27002' }, { _id: 2, host: '$HOSTNAME:27003' } ]}"
mongo admin --port 27001 -u $USERNAME -p $PASSWORD --eval "db.runCommand({ replSetInitiate: $CONFIG })"

waitForMongo 27002 $USERNAME $PASSWORD
waitForMongo 27003 $USERNAME $PASSWORD

mongo admin --port 27001 -u $USERNAME -p $PASSWORD --eval "db.runCommand({ setParameter: 1, quiet: 1 })"
mongo admin --port 27002 -u $USERNAME -p $PASSWORD --eval "db.runCommand({ setParameter: 1, quiet: 1 })"
mongo admin --port 27003 -u $USERNAME -p $PASSWORD --eval "db.runCommand({ setParameter: 1, quiet: 1 })"

echo "REPLICA SET ONLINE"


trap 'echo "KILLING"; kill $DB1_PID $DB2_PID $DB3_PID; wait $DB1_PID; wait $DB2_PID; wait $DB3_PID' SIGINT SIGTERM EXIT

wait $DB1_PID
wait $DB2_PID
wait $DB3_PID
