![logo](https://raw.githubusercontent.com/DSecureMe/vmc/master/images/vmp.png)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# What is VMC
**[VMC](https://github.com/DSecureMe/vmc)** (Vulnerability Management Center) is a platform created to make vulnerability management simple, easy and clean.

# How to use
To run demo instance you need:
- make
- docker (tested on version 20.10.13), followed [these steps](https://docs.docker.com/engine/install/debian/)
- docker compose (tested on version v2.2.3), followed [these steps](https://docs.docker.com/compose/cli-command/)

**NOTE:**
Remember to install compose not as root, but as that normal user. Pay close attention to the [following steps](https://docs.docker.com/compose/cli-command/#install-on-linux)

Then simply run:
```
git clone https://github.com/DSecureMe/vmc-demo.git && cd vmc-demo
make up
```

When all images are downloaded and kibana starts responding correctly on port `5601`:
```
make demodata
```

Services:
- on port `:5601` you can find Kibana panel with sample KPIs.
- on port `:8081` you can find Ralph with sample assets (login ralph, password: ralph).
- on port `:9000` you can find The Hive with the sample alerts(login admin, password: admin).
- on port `:8080` you can find VMC admin panel with the sample configuration (login admin, password: admin).

More guides you can find on [doc report](https://github.com/DSecureMe/vmc-docs)

# Configuration files
All configs you may find in `demo/config/`

# Demo configuration file
Once build it will be in `/etc/vmc/`
In demo repo you can find it in `/demo/config/vmc/demo.yml`
```
#VMC
vmc.ssl: False
vmc.domain: localhost
vmc.port: 80

#Redis
redis.url: redis://redis:6379/1

#Elastic Search
elasticsearch.hosts: ["http://elasticsearch:9200"]

#database
database.engine: django.db.backends.postgresql_psycopg2
database.name: vmc
database.user: user
database.password: password
database.host: postgres
database.port: 5432

# Queue
rabbitmq.username: vmc
rabbitmq.password: test_vmc
rabbitmq.host: rabbitmq
rabbitmq.port: 5672

# Secret
secret_key: "*********************************************"
debug: true

# Admin Service Name
admin_service_name: admin
```

# Credit
[VMC](https://github.com/DSecureMe/vmc)

[VMC Docker](https://github.com/DSecureMe/vmc-docker)

[DSecure.me](https://dsecure.me)
