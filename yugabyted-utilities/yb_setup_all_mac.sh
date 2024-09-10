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
NODE2_IP="127.0.0.2"
NODE3_IP="127.0.0.3"

NODE1_CLOUD="cloud.region1.zone1"
NODE2_CLOUD="cloud.region1.zone2"
NODE3_CLOUD="cloud.region1.zone3"

YB_VERSION="2024.1.2.0"
YB_BUILD="b77"
YB_URL="https://downloads.yugabyte.com/releases/${YB_VERSION}/yugabyte-${YB_VERSION}-${YB_BUILD}-darwin-x86_64.tar.gz"
YB_SOFTWARE_DIR="$HOME/yb-software"
YB_INSTALL_DIR="${YB_SOFTWARE_DIR}/yugabyte-${YB_VERSION}"

# gFlags
TS_GFLAGS="ysql_enable_packed_row=true,ysql_beta_features=true,yb_enable_read_committed_isolation=true,enable_deadlock_detection=true,enable_wait_queues=true"
MS_GFLAGS="ysql_enable_packed_row=true,ysql_beta_features=true,transaction_tables_use_preferred_zones=true"

# Create base directory if it does not exist
if [ ! -d $YB_SOFTWARE_DIR ]
then
     mkdir -p $YB_SOFTWARE_DIR
     # Download YB for Mac
     printf "\nDownloading YugabyteDB...\n"
     curl $YB_URL > $YB_SOFTWARE_DIR/yugabyte-${YB_VERSION}-${YB_BUILD}-darwin-x86_64.tar.gz

     # Extract Tarball
     printf "\nExtracting Tarball...\n"
     tar xfz $YB_SOFTWARE_DIR/yugabyte-${YB_VERSION}-${YB_BUILD}-darwin-x86_64.tar.gz --directory $YB_SOFTWARE_DIR
else
     echo "YB base directory already exists"
fi

# Enable additional loopback addresses:
sudo ifconfig lo0 alias $NODE1_IP up
sudo ifconfig lo0 alias $NODE2_IP up
sudo ifconfig lo0 alias $NODE3_IP up

# Start primary node
printf "\nStarting primary node...\n"
$YB_INSTALL_DIR/bin/yugabyted start --advertise_address=$NODE1_IP --base_dir=$YB_SOFTWARE_DIR/node1 --cloud_location=$NODE1_CLOUD --fault_tolerance=zone --tserver_flags="$TS_GFLAGS" --master_flags="$MS_GFLAGS"

sleep 5

# Start 2nd node
printf "\nStarting node 2...\n"
$YB_INSTALL_DIR/bin/yugabyted start --advertise_address=$NODE2_IP --base_dir=$YB_SOFTWARE_DIR/node2 --cloud_location=$NODE2_CLOUD --fault_tolerance=zone --join=$NODE1_IP --tserver_flags="$TS_GFLAGS" --master_flags="$MS_GFLAGS"

sleep 5

# Start 3rd node
printf "\nStarting node 3...\n"
$YB_INSTALL_DIR/bin/yugabyted start --advertise_address=$NODE3_IP --base_dir=$YB_SOFTWARE_DIR/node3 --cloud_location=$NODE3_CLOUD --fault_tolerance=zone --join=$NODE1_IP --tserver_flags="$TS_GFLAGS" --master_flags="$MS_GFLAGS"

# Wait a bit
printf "\nFinishing up, please wait 20 seconds...\n"
sleep 20

# Set data placement policy
$YB_INSTALL_DIR/bin/yugabyted configure data_placement --fault_tolerance=zone --base_dir=$YB_SOFTWARE_DIR/node1

# Check connectivity to each node
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE1_IP -p 5433 ; do sleep 1 ; done
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE2_IP -p 5433 ; do sleep 1 ; done
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE3_IP -p 5433 ; do sleep 1 ; done

# Verify 3 nodes are up!
printf "\nYugabyteDB Universe...\n"
$YB_INSTALL_DIR/bin/ysqlsh -h $NODE1_IP -c "SELECT host, node_type, cloud, region, zone FROM yb_servers() ORDER BY host;"

exit
