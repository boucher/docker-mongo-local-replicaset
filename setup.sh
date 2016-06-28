#!/bin/bash
set -e

USERNAME=${USERNAME:=dev}
PASSWORD=${PASSWORD:=dev}

if [ ! "$(ls -A /data/db/db1)" ]; then
    NEEDS_SETUP=1

    mkdir /data/db/db1
    mkdir /data/db/db2
    mkdir /data/db/db3

    mongod --smallfiles --noprealloc --dbpath /data/db/db1 &
    MONGO_PID=$!

    sleep 3
    echo "CREATING USER ACCOUNT"
    mongo admin --eval "db.createUser({ user: '$USERNAME', pwd: '$PASSWORD', roles: ['root', 'restore', 'readWriteAnyDatabase', 'dbAdminAnyDatabase'] })"

    echo "KILLING MONGO"
    kill $MONGO_PID
    sleep 3
fi

echo "WRITING KEYFILE"

openssl rand -base64 741 > /var/mongo_keyfile
chown mongodb /var/mongo_keyfile
chmod 600 /var/mongo_keyfile

echo "STARTING CLUSTER"

mongod --port 27001 --smallfiles --noprealloc --dbpath /data/db/db1 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
DB1_PID=$!
mongod --port 27002 --smallfiles --noprealloc --dbpath /data/db/db2 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
DB2_PID=$!
mongod --port 27003 --smallfiles --noprealloc --dbpath /data/db/db3 --auth --replSet rs0 --keyFile /var/mongo_keyfile  &
DB3_PID=$!

if [ "$NEEDS_SETUP" ]; then
    sleep 10
    echo "CONFIGURING REPLICA SET"
    CONFIG='{ _id: "rs0", members: [{_id: 0, host: "localhost:27001", priority: 2 }, { _id: 1, host: "localhost:27002" }, { _id: 2, host: "localhost:27003" } ]}'
    mongo admin --port 27001 -u $USERNAME -p $PASSWORD --eval "db.runCommand({ replSetInitiate: $CONFIG })"
fi

term_handler() {
  if [ $DB1_PID -ne 0 ]; then
    echo "TRAP"
    kill -SIGTERM "$DB1_PID"
    kill -SIGTERM "$DB2_PID"
    kill -SIGTERM "$DB3_PID"
    wait "$DB1_PID"
    wait "$DB2_PID"
    wait "$DB3_PID"
  fi

  exit 1;
}

# setup handlers
trap 'kill ${!}; term_handler' SIGTERM SIGINT

# wait indefinetely
while true
do
  tail -f /dev/null & wait ${!}
done
