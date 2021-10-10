#!/bin/bash

echo "Creating admin user"
createadmin="use admin; db.createUser({ user: "root", pwd: "example", roles: [ "root" ] });"
docker exec -it $(docker ps -qf label=com.docker.swarm.service.name=waves-voting_mongo-replica-1) bash -c "echo '${createadmin}' | mongo"
docker exec -it $(docker ps -qf label=com.docker.swarm.service.name=waves-voting_mongo-replica-1) mongod --shutdown && mongod --smallfiles --auth --fork --logpath /var/log/mongod.log --replSet rs-waves-voting --oplogSize 3
echo "Intializing replica set on master"
replicate="rs.initiate(); sleep(1000); cfg = rs.conf(); cfg.members[0].host = \"mongo-replica-1:27017\"; rs.reconfig(cfg); rs.add({ host: \"mongo-replica-2:27017\", priority: 0.5 }); rs.add({ host: \"mongo-replica-3:27017\", priority: 0.5 }); rs.status();"
docker exec -it $(docker ps -qf label=com.docker.swarm.service.name=waves-voting_mongo-replica-1) bash -c "echo '${replicate}' | mongo -u "root" -p "example" --authenticationDatabase admin"