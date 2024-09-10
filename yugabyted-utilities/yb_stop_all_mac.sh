#!/bin/bash
# Customizable variables
NODE1_IP="127.0.0.1"
NODE2_IP="127.0.0.2"
NODE3_IP="127.0.0.3"

YB_VERSION="2024.1.2.0"
YB_BUILD="b77"
YB_SOFTWARE_DIR="$HOME/yb-software"
YB_INSTALL_DIR="${YB_SOFTWARE_DIR}/yugabyte-${YB_VERSION}"


# Stop 2nd node
printf "\nStopping node 2...\n"
$YB_INSTALL_DIR/bin/yugabyted stop  --base_dir=$YB_SOFTWARE_DIR/node2

# Stop 3rd node
printf "\nStopping node 3...\n"
$YB_INSTALL_DIR/bin/yugabyted stop  --base_dir=$YB_SOFTWARE_DIR/node3

# Stop primary node
printf "\nStopping primary node...\n"
$YB_INSTALL_DIR/bin/yugabyted stop  --base_dir=$YB_SOFTWARE_DIR/node1 

# Destroy extra nodes (if you scaled out the cluster)
printf "\nStopping extra nodes created due to scale out...\n"
$YB_INSTALL_DIR/bin/yugabyted stop  --base_dir=$YB_SOFTWARE_DIR/node4
$YB_INSTALL_DIR/bin/yugabyted stop  --base_dir=$YB_SOFTWARE_DIR/node5
$YB_INSTALL_DIR/bin/yugabyted stop  --base_dir=$YB_SOFTWARE_DIR/node6


printf "\nYugabyteDB Universe...All Nodes Stopped\n"
