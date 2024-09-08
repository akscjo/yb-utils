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
printf "\Destroying node 2...\n"
$YB_INSTALL_DIR/bin/yugabyted destroy  --base_dir=$YB_SOFTWARE_DIR/node2

# Stop 3rd node
printf "\Destroying node 3...\n"
$YB_INSTALL_DIR/bin/yugabyted destroy  --base_dir=$YB_SOFTWARE_DIR/node3

# Stop primary node
printf "\Destroying primary node...\n"
$YB_INSTALL_DIR/bin/yugabyted destroy  --base_dir=$YB_SOFTWARE_DIR/node1 


printf "\nYugabyteDB Universe...All Nodes Stopped\n"