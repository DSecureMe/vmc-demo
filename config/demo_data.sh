echo "Elastalert: Create Indexes"
docker exec -it elastalert /usr/bin/elastalert-create-index --config /opt/elastalert/config.yaml

echo "HIVE: create database (superuser login: admin, password: admin)"
docker exec -it elasticsearch chmod +x /test_data/load.sh
docker exec -it elasticsearch /test_data/load.sh

echo "Ralph: Make migrations"
docker exec -it ralph_web ralphctl migrate

echo "Ralph: Load demo data  (login: ralph, password: ralph)"
docker exec -it ralph_web ralphctl demodata
docker exec -it ralph_web ralphctl sitetree_resync_apps
docker exec -it ralph_web python3 /test_data/generate_ips.py

echo "VMC: Load data (superuser login: admin, password: admin)"
docker exec -it vmc_admin python3 -m vmc loaddata /test_data/demo_data.json
docker exec -it vmc_admin python3 -m vmc create_index

echo "Kibana: Import Sample Dashboards and KPIs"
docker exec -it kibana chmod +x /test_data/load.sh
docker exec -it kibana /test_data/load.sh

echo "VMC: Prepare demo data"
docker exec -it vmc_admin python3 -W ignore /test_data/generate_vulns.py