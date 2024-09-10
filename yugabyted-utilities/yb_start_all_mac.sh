#!/bin/bash
# Customizable variables
NODE1_IP="127.0.0.1"
NODE2_IP="127.0.0.2"
NODE3_IP="127.0.0.3"

YB_VERSION="2024.1.2.0"
YB_BUILD="b77"
YB_SOFTWARE_DIR="$HOME/yb-software"
YB_INSTALL_DIR="${YB_SOFTWARE_DIR}/yugabyte-${YB_VERSION}"

# Start primary node
printf "\Starting primary node...\n"
$YB_INSTALL_DIR/bin/yugabyted start  --base_dir=$YB_SOFTWARE_DIR/node1 
sleep 5

# Start 2nd node
printf "\nStarting node 2...\n"
$YB_INSTALL_DIR/bin/yugabyted start  --base_dir=$YB_SOFTWARE_DIR/node2
sleep 5

# Start 3rd node
printf "\nStarting node 3...\n"
$YB_INSTALL_DIR/bin/yugabyted start  --base_dir=$YB_SOFTWARE_DIR/node3

# Wait a bit
printf "\nFinishing up, please wait 20 seconds...\n"
sleep 20


# Check connectivity to each node
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE1_IP -p 5433 ; do sleep 1 ; done
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE2_IP -p 5433 ; do sleep 1 ; done
until $YB_INSTALL_DIR/postgres/bin/pg_isready -h $NODE3_IP -p 5433 ; do sleep 1 ; done

# Verify 3 nodes are up!
printf "\nYugabyteDB Universe...\n"
$YB_INSTALL_DIR/bin/ysqlsh -h $NODE1_IP -c "SELECT host, node_type, cloud, region, zone FROM yb_servers() ORDER BY host;"

exit
