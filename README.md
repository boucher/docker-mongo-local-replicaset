# MongoDB Local ReplicaSet

Sometimes you need a replica set in your local environment (perhaps you want to use the oplog). But it's somewhat involved to spin up a series of mongo containers and provide the correct configuration. This docker image will create a self-contained 3 node replica set (that is, all three nodes are running in one container).

**THIS IS ONLY USEFUL FOR LOCAL DEVELOPMENT**

## Using

You need to know the following:

### LOGIN INFO

User info is configured on the admin database:

  - username: dev
  - password: dev

### PORTS
Each instance exposes a port, all listening on 0.0.0.0 interface:

  - db1: 27001 [primary]
  - db2: 27002
  - db3: 27003

### DATA
The container will create volumes, but you can mount them to your host at these paths:

  - db1: /data/db1 [primary]
  - db2: /data/db2
  - db3: /data/db3

### REPLICA SET NAME
It's called: `rs0`

## Notes

If you mount in the /data/db1 volume, the container will not go through it's initialization process, but it will also assume that you have mounted all 3 volumes -- so mount all 3 or none. You can customize the username/password by providing USERNAME/PASSWORD environment variables (but you probably don't need to).

## EXAMPLE RUN

    `docker run -d --name mongo -v $(pwd)/db1:/data/db1 -v $(pwd)/db2:/data/db2 -v $(pwd)/db3:/data/db3 boucher/mongo-local-replicaset`

### EXAMPLE MONGO CONNECTION STRING FROM SOME OTHER CONTAINER:

    `mongodb://dev:dev@mongo:27001,mongo:27002,mongo:27003/db?authSource=admin`
