#!/bin/bash
#
# This script runs the blobstream integration tests.

# TODO: Host?
RPC_HOST="127.0.0.1"
RPC_PORT=5050

display_help() {
  echo "Usage: $0 [option...] {arguments...}"
  echo

  echo "   -h, --help                 display help"
  echo "   -p, --rpc-port             specify the rpc port (default: 5050)"

  echo
  echo "Example: $0"
}

# Parse command line arguments
while getopts ":hp:-:" opt; do
  case ${opt} in
    - )
      case "${OPTARG}" in
        help )
          display_help
          exit 0
          ;;
        rpc-port=*)
          RPC_PORT="${OPTARG#*=}"
          ;;
        rpc-port )
          RPC_PORT="$2"
          ;;
        * )
          echo "Invalid option: --$OPTARG" 1>&2
          display_help
          exit 1
          ;;
      esac
      ;;
    h )
      display_help
      exit 0
      ;;
    p )
      RPC_PORT=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      display_help
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      display_help
      exit 1
      ;;
  esac
done

#TODO: argument?
RPC_URL=http://$RPC_HOST:$RPC_PORT

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORK_DIR=$SCRIPT_DIR/..

OUTPUT_DIR=$HOME/.blobstream-integration-tests
TIMESTAMP=$(date +%s)
LOG_DIR=$OUTPUT_DIR/logs/$TIMESTAMP
TMP_DIR=$OUTPUT_DIR/tmp/$TIMESTAMP

# TODO: Clean option to remove old logs and state
rm -rf $OUTPUT_DIR/logs/*
rm -rf $OUTPUT_DIR/tmp/*
mkdir -p $LOG_DIR
mkdir -p $TMP_DIR

echo "Running integration tests..."

# $LOG_DIR=$ // Clean on every run?
# katana --disable-fee 2&>1 > katana-output.log
# sncast --url http://0.0.0.0:5050 account add --name account1 --address 0x6b86e40118f29ebe393a75469b4d926c7a44c2e2681b6d319520b7c1156d114 --private-key 0x1c9053c053edf324aec366a34c6901b1095b07af69495bffec7d7fe21effb1b --add-profile KATANA

# TODO: Use snfoundry.toml | Env var | CLI arg | Default
ACCOUNT_NAME=integration_account
ACCOUNT_ADDRESS=0x328ced46664355fc4b885ae7011af202313056a7e3d44827fb24c9d3206aaa0
ACCOUNT_PRIVATE_KEY=0x856c96eaa4e7c40c715ccc5dacd8bf6e
ACCOUNT_PROFILE=starknet-devnet
ACCOUNT_FILE=$TMP_DIR/starknet_accounts.json

# sncast --url $RPC_URL account add --name $ACCOUNT_NAME --address $ACCOUNT1_ADDRESS --private-key $ACCOUNT1_PRIVATE_KEY --add-profile $ACCOUNT1_PROFILE
# OZ_ACCOUNT_FILE=$HOME/.starknet_accounts/starknet_open_zeppelin_accounts.json

# echo "Given RPC URL: $RPC_URL"
# starkli balance 0x6b86e40118f29ebe393a75469b4d926c7a44c2e2681b6d319520b7c1156d114 --rpc $RPC_URL

echo "Starting the starknet-devnet node..."

STARKNET_DEVNET_DIR=$WORK_DIR/starknet-devnet-rs/
STARKNET_DEVNET_BIN=$STARKNET_DEVNET_DIR/target/debug/starknet-devnet

# TODO: dump options, no output,  ...
# Start the starknet-devnet node
kill $(ps aux | grep starknet-devnet\ --seed\ 42 | grep -v grep | awk '{print $2}')
touch $LOG_DIR/starknet-devnet.log
$STARKNET_DEVNET_BIN --seed 42 --host $RPC_HOST --port $RPC_PORT 2>&1 > $LOG_DIR/starknet-devnet.log &
STARKNET_DEVNET_PID=$!
# ./target/debug/starknet-devnet --seed 1 --dump-on exit --dump-path ~/.starknet_devnet --state-archive-capacity full

# TODO: Wait for output of line in log
sleep 2

echo
echo "Adding account..."
# TODO: path-to-scarb-toml?, 
# sncast --url $RPC_URL --accounts-file $ACCOUNT_FILE account add --name $ACCOUNT_NAME --address $ACCOUNT_ADDRESS --private-key $ACCOUNT_PRIVATE_KEY --add-profile $ACCOUNT_PROFILE
sncast --url $RPC_URL --accounts-file $ACCOUNT_FILE account add --name $ACCOUNT_NAME --address $ACCOUNT_ADDRESS --private-key $ACCOUNT_PRIVATE_KEY

#TODO: Cleanup outputs of scripts
echo
echo "Declaring contract(s)..."

CONTRACT_DIR=$WORK_DIR/contracts/test_contracts
CLASS_NAME="HelloStarknet"

#cd $CONTRACT_DIR && SCARB=$WORK_DIR/tests/scarb/target/debug/scarb sncast --url $RPC_URL --accounts-file $ACCOUNT_FILE --account $ACCOUNT_NAME --wait declare --contract-name $CLASS_NAME
CLASS_DECLARE_RESULT=$(cd $CONTRACT_DIR && SCARB=$WORK_DIR/scarb/target/debug/scarb sncast --url $RPC_URL --accounts-file $ACCOUNT_FILE --account $ACCOUNT_NAME --wait --json declare --contract-name $CLASS_NAME | tail -n 1)
CLASS_HASH=$(echo $CLASS_DECLARE_RESULT | jq -r '.class_hash')
echo "Declared class \"$CLASS_NAME\" with hash $CLASS_HASH"

echo
echo "Deploying contract(s)..."

CONTRACT_DEPLOY_RESULT=$(sncast --url $RPC_URL --accounts-file $ACCOUNT_FILE --account $ACCOUNT_NAME --wait --json deploy --class-hash $CLASS_HASH | tail -n 1)
CONTRACT_ADDRESS=$(echo $CONTRACT_DEPLOY_RESULT | jq -r '.contract_address')
echo "Deployed contract \"$CLASS_NAME\" with address $CONTRACT_ADDRESS"

echo
echo "Running Multicall(s)..."

MULTICALL_TEMPLATE_DIR=$CONTRACT_DIR/tests/multicalls

HELLO_STARKNET_MULTI_TEMPLATE=$MULTICALL_TEMPLATE_DIR/HelloStarknet.toml
HELLO_STARKNET_MULTI=$TMP_DIR/HelloStarknet.toml
sed "s/\$CONTRACT_ADDRESS/$CONTRACT_ADDRESS/g" $HELLO_STARKNET_MULTI_TEMPLATE > $HELLO_STARKNET_MULTI
sncast --url $RPC_URL --accounts-file $ACCOUNT_FILE --account $ACCOUNT_NAME --wait multicall run --path $HELLO_STARKNET_MULTI

echo
echo "Checking results..."
sncast --url $RPC_URL --accounts-file $ACCOUNT_FILE --account $ACCOUNT_NAME --wait call --contract-address $CONTRACT_ADDRESS --function get_balance --block-id latest

echo
echo "Stopping the starknet-devnet node..."
kill $STARKNET_DEVNET_PID

echo
echo "Integration tests finished."
