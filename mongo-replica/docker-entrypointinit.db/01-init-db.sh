#!/bin/bash

if ! [[ -a /data/db/mydb-initialized ]]; then
	mongod --shutdown \
	&& mongod --fork --logpath /var/log/mongod.log \
	&& mongo <<-EOF
		use admin;
		db.createUser({ user: "root", pwd: "example", roles: [ "root" ] });
	EOF
	
	mongod --shutdown \
		&& mongod --auth --fork --logpath /var/log/mongod.log --replSet rs-waves-voting 
		&& mongo -u "root" -p "example" --authenticationDatabase admin <<-EOF
			rs.initiate(); 
			sleep(1000); 
			cfg = rs.conf(); 
			cfg.members[0].host = \"mongo-replica-1:27017\"; 
			rs.reconfig(cfg); 
			rs.add({ host: \"mongo-replica-2:27017\", priority: 0.5 }); 
			rs.add({ host: \"mongo-replica-3:27017\", priority: 0.5 }); 
			rs.status();
		EOF
	
	touch /data/db/mydb-initialized
fi