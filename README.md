# MongoDB Local ReplicaSet

Sometimes you need a replica set in your local environment (perhaps you want to use the oplog). But it's somewhat involved to spin up a series of mongo containers and provide the correct configuration. This docker image will create a self-contained 3 node replica set (that is, all three nodes are running in one container).

**THIS IS ONLY USEFUL FOR LOCAL DEVELOPMENT**

## Using

You need to know the following:

#### LOGIN INFO

User info is configured on the admin database:

  - username: `dev`
  - password: `dev`

#### PORTS
Each instance exposes a port, all listening on 0.0.0.0 interface:

  - db1: `27001` [primary]
  - db2: `27002`
  - db3: `27003`

#### DATA
The container will create one volume at `/data/db`, with three directories. You can also mount one volume
containing all 3 directories or mount three separate volumes to your host at these paths:

  - db1: `/data/db/db1` [primary]
  - db2: `/data/db/db2`
  - db3: `/data/db/db3`

#### REPLICA SET NAME
It's called: `rs0`

## Notes

If you mount something into `/data/db/db1`, the container will not go through it's initialization process, but it will also assume that you have all 3 directories -- so mount all or none. You can customize the username/password by providing `USERNAME`/`PASSWORD` environment variables (but you probably don't need to).

### Example Run

    docker run -d --name mongo -v $(pwd)/data:/data boucher/mongo-local-replicaset

### Example Mongo Connection String (from another container)

    mongodb://dev:dev@mongo:27001,mongo:27002,mongo:27003/db?authSource=admin
