#!/bin/bash
# Mac Version
# Doc reference: https://docs.yugabyte.com/preview/quick-start/

# Python must be installed!
# To get Python: https://www.python.org/downloads/
# Might need to add a symbolic link?
#   ln -s -f /usr/local/bin/python3 /usr/local/bin/python
# Verify: python --version


# Customizable variables
NODE1_IP="127.0.0.1"
NODE4_IP="127.0.0.4"
NODE5_IP="127.0.0.5"
NODE6_IP="127.0.0.6"

NODE4_CLOUD="cloud.region1.zone1"
NODE5_CLOUD="cloud.region1.zone2"
NODE6_CLOUD="cloud.region1.zone3"

YB_VERSION="2024.1.2.0"
YB_BUILD="b77"
YB_URL="https://downloads.yugabyte.com/releases/${YB_VERSION}/yugabyte-${YB_VERSION}-${YB_BUILD}-darwin-x86_64.tar.gz"
YB_SOFTWARE_DIR="$HOME/yb-software"
YB_INSTALL_DIR="${YB_SOFTWARE_DIR}/yugabyte-${YB_VERSION}"

# gFlags
TS_GFLAGS="ysql_enable_packed_row=true,ysql_beta_features=true,yb_enable_read_committed_isolation=true,enable_deadlock_detection=true,enable_wait_queues=true"
MS_GFLAGS="ysql_enable_packed_row=true,ysql_beta_features=true,transaction_tables_use_preferred_zones=true"


# Enable additional loopback addresses:
sudo ifconfig lo0 alias $NODE4_IP up
sudo ifconfig lo0 alias $NODE5_IP up
sudo ifconfig lo0 alias $NODE6_IP up

# Start 4th node
printf "\nStarting primary node...\n"
$YB_INSTALL_DIR/bin/yugabyted start --advertise_address=$NODE4_IP --base_dir=$YB_SOFTWARE_DIR/node4 --cloud_location=$NODE4_CLOUD --fault_tolerance=zone --join=$NODE1_IP --tserver_flags="$TS_GFLAGS" --master_flags="$MS_GFLAGS"

sleep 5

# Start 5th node
printf "\nStarting node 2...\n"
$YB_INSTALL_DIR/bin/yugabyted start --advertise_address=$NODE5_IP --base_dir=$YB_SOFTWARE_DIR/node5 --cloud_location=$NODE5_CLOUD --fault_tolerance=zone --join=$NODE1_IP --tserver_flags="$TS_GFLAGS" --master_flags="$MS_GFLAGS"

sleep 5

# Start 6th node
printf "\nStarting node 3...\n"
$YB_INSTALL_DIR/bin/yugabyted start --advertise_address=$NODE6_IP --base_dir=$YB_SOFTWARE_DIR/node6 --cloud_location=$NODE6_CLOUD --fault_tolerance=zone --join=$NODE1_IP --tserver_flags="$TS_GFLAGS" --master_flags="$MS_GFLAGS"

# Wait a bit
printf "\nFinishing up, please wait 20 seconds...\n"
sleep 20

# Set data placement policy
$YB_INSTALL_DIR/bin/yugabyted configure data_placement --fault_tolerance=zone --base_dir=$YB_SOFTWARE_DIR/node1

# Check connectivity to each node
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE4_IP -p 5433 ; do sleep 1 ; done
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE5_IP -p 5433 ; do sleep 1 ; done
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE6_IP -p 5433 ; do sleep 1 ; done

# Verify 3 nodes are up!
printf "\nYugabyteDB Universe...\n"
$YB_INSTALL_DIR/bin/ysqlsh -h $NODE1_IP -c "SELECT host, node_type, cloud, region, zone FROM yb_servers() ORDER BY host;"

exit
