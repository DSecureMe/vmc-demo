![logo](https://dsecure.me/wp-content/uploads/2019/11/dSecure-1.png)

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# What is VMC
**[VMC](https://github.com/DSecureMe/vmc)** (Vulnerability Management Center) is a platform created to make vulnerability management simple, easy and clean.

# How to use
## To run demo
Open demo folder and build (it may take couple minutes)
```
make up
make demodata # If you want to configure and genrate demodata to see how everything works.
```
Then:
- on port `:5601` you can find Kibana panel with sample KPIs.
- on port `:8081` you can find Ralph with sample assets (login ralph, password: ralph).
- on port `:9000` you can find The Hive with the sample alerts(login admin, password: admin).
- on port `:8080` you can find VMC admin panel with the sample configuration (login admin, password: admin).

More guides will be published on [doc report](https://github.com/DSecureMe/vmc-docs) very soon

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


# Requirments
* docker
* docker compose
* make

# Credit
[VMC](https://github.com/DSecureMe/vmc)

[VMC Docker](https://github.com/DSecureMe/vmc-docker)

[DSecure.me](https://dsecure.me)
