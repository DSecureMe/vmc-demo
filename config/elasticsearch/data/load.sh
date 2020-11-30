#!/usr/bin/env bash

curl -XPUT 'http://localhost:9200/_snapshot/the_hive_backup' -H 'Content-Type: application/json' -d '{
    "type": "fs",
    "settings": {
        "location": "/test_data",
        "compress": true
    }
}'

curl -XPOST 'http://localhost:9200/_snapshot/the_hive_backup/snapshot_2/_restore' -H 'Content-Type: application/json'  -d '
{
  "indices": "hive_16"
}'
