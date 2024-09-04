#!/bin/bash

###############################################################################
# YugabyteDB Deployment Script for AWS EC2 Instances
#
# This script automates the deployment of a YugabyteDB cluster across three 
# EC2 instances. It can perform two main tasks:
#   1. Setup (Download and Install YugabyteDB)
#   2. Start YugabyteDB Process
#
# USAGE:
#   ./deploy_yugabyte_cluster.sh [--skip-setup]
#
# ARGUMENTS:
#   --skip-setup   Optional. Skips the setup steps (download and install 
#                  YugabyteDB). If provided, the script will only start the 
#                  yugabyted process on each node.
#
# REQUIREMENTS:
#   - SSH access to all three EC2 instances with appropriate SSH keys (.pem files).
#   - Network configuration allowing communication between nodes using private IPs.
#   - Supported Linux distribution with yum as the package manager (e.g., Amazon Linux).
#
# EXAMPLES:
#   Run full setup and start the YugabyteDB cluster:
#       ./deploy_yugabyte_cluster.sh
#
#   Skip setup and only start the YugabyteDB process:
#       ./deploy_yugabyte_cluster.sh --skip-setup
#
# DESCRIPTION:
#   - The script sets up YugabyteDB by downloading and installing it on each node,
#     setting the necessary environment variables, and configuring system limits.
#   - It then starts the yugabyted process on each node, with nodes 2 and 3 joining 
#     the cluster initiated by node 1.
#
# NOTES:
#   - Ensure the SSH user has the necessary permissions to execute commands on the remote nodes.
#   - The script assumes you are running it from a server that has SSH access to all three nodes.
###############################################################################


# Customizable variables
NODE1_IP="10.37.3.166"
NODE2_IP="10.37.1.168"
NODE3_IP="10.37.2.48"

NODE1_CLOUD="aws.us-east-1.us-east-1c"
NODE2_CLOUD="aws.us-east-1.us-east-1a"
NODE3_CLOUD="aws.us-east-1.us-east-1b"

SSH_USER="ec2-user"
SSH_KEY_PATH="/home/ec2-user/keys/kp-CANNON-aws.pem"

YB_VERSION="2024.1.2.0"
YB_BUILD="b77"
YB_URL="https://downloads.yugabyte.com/releases/${YB_VERSION}/yugabyte-${YB_VERSION}-${YB_BUILD}-linux-x86_64.tar.gz"
YB_SOFTWARE_DIR="~/yb-software"
YB_INSTALL_DIR="${YB_SOFTWARE_DIR}/yugabyte-${YB_VERSION}"

# gFlags
TS_GFLAGS="ysql_enable_packed_row=true,ysql_beta_features=true,yb_enable_read_committed_isolation=true,enable_deadlock_detection=true,enable_wait_queues=true"
MS_GFLAGS="ysql_enable_packed_row=true,ysql_beta_features=true,transaction_tables_use_preferred_zones=true"

# Flag to control setup step
SKIP_SETUP=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --skip-setup)
      SKIP_SETUP=true
      shift # Remove --skip-setup from processing
      ;;
    *)
      shift # Remove generic argument from processing
      ;;
  esac
done

# Function to run commands on a remote server
run_remote_command() {
  local node_ip=$1
  local command=$2

  ssh -i "${SSH_KEY_PATH}" "${SSH_USER}@${node_ip}" "${command}"
}

# Function to set up YugabyteDB on a node
setup_node() {
  local node_ip=$1
  echo "Setting up YugabyteDB on node ${node_ip}..."

  # Commands to be executed on the remote node
  remote_commands="
    # Check if wget is installed, and install if it is not
    if ! command -v wget &> /dev/null; then
      echo 'wget not found, installing...'
      sudo yum install -y wget
    fi

    # Set ulimits
    echo 'Setting appropriate YB ulimits...'
    cat > /tmp/99-yugabyte-limits.conf <<EOF
$SSH_USER soft core unlimited
$SSH_USER hard core unlimited
$SSH_USER soft data unlimited
$SSH_USER hard data unlimited
$SSH_USER soft priority 0
$SSH_USER hard priority 0
$SSH_USER soft fsize unlimited
$SSH_USER hard fsize unlimited
$SSH_USER soft sigpending 119934
$SSH_USER hard sigpending 119934
$SSH_USER soft memlock 64
$SSH_USER hard memlock 64
$SSH_USER soft nofile 1048576
$SSH_USER hard nofile 1048576
$SSH_USER soft stack 8192
$SSH_USER hard stack 8192
$SSH_USER soft rtprio 0
$SSH_USER hard rtprio 0
$SSH_USER soft nproc 12000
$SSH_USER hard nproc 12000
EOF

    sudo cp /tmp/99-yugabyte-limits.conf /etc/security/limits.d/99-yugabyte-limits.conf

    # Create directory, download YugabyteDB, and install
    mkdir -p ${YB_SOFTWARE_DIR} && cd ${YB_SOFTWARE_DIR} &&
    wget ${YB_URL} &&
    tar xvfz yugabyte-${YB_VERSION}-${YB_BUILD}-linux-x86_64.tar.gz &&
    cd yugabyte-${YB_VERSION}/ &&
    ./bin/post_install.sh

    # Update .bash_profile with YugabyteDB paths
    echo 'export PATH=${YB_INSTALL_DIR}/bin:${YB_INSTALL_DIR}/postgres/bin:\$PATH' >> ~/.bash_profile
    echo 'export ts_gf=\"${TS_GFLAGS}\"' >> ~/.bashrc
    echo 'export ms_gf=\"${MS_GFLAGS}\"' >> ~/.bashrc
    source ~/.bashrc
    source ~/.bash_profile
  "

  run_remote_command "${node_ip}" "${remote_commands}"
}

# Function to start YugabyteDB on a node
start_node() {
  local node_ip=$1
  local join_ip=$2
  local base_dir=$3
  local zone=$4

  echo "Starting YugabyteDB on node ${node_ip}..."
  
  # Conditionally add the --join flag for nodes 2 and 3
  if [ -z "${join_ip}" ]; then
    join_flag=""
  else
    join_flag="--join=${join_ip}"
  fi

  # Command to start yugabyted process
  remote_start_command="
    source ~/.bash_profile &&
    yugabyted start --advertise_address=${node_ip} ${join_flag} --cloud_location=${zone} --base_dir=${base_dir} --fault_tolerance=zone --tserver_flags=\$ts_gf --master_flags=\$ms_gf
  "

  run_remote_command "${node_ip}" "${remote_start_command}"
}

# Deploy YugabyteDB on all nodes if setup is not skipped
if [ "$SKIP_SETUP" = false ]; then
  setup_node "${NODE1_IP}"
  setup_node "${NODE2_IP}"
  setup_node "${NODE3_IP}"
fi

# Start the nodes one by one with a 30-second wait time between each
start_node "${NODE1_IP}" "" "~/node1" "${NODE1_CLOUD}"
sleep 3

start_node "${NODE2_IP}" "${NODE1_IP}" "~/node2" "${NODE2_CLOUD}"
sleep 3

start_node "${NODE3_IP}" "${NODE1_IP}" "~/node3" "${NODE3_CLOUD}"

echo "YugabyteDB cluster setup complete."
