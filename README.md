# klaytn-node-provisioner

**Note:** This is not fully tested. Use the software at your own risk.

## How to run provisioner

```
# Set proper AWS IAM (e.g. access/private key)

ansible-playbook -i inventories/development playbook.yml 
```

## Test klaytn node

```bash
export NODE_URL=http://localhost:8551

curl -X "POST" $NODE_URL \
  -H 'Content-Type: application/json' \
  -d $'{
    "jsonrpc": "2.0",
    "method": "web3_clientVersion",
    "id": "67"
  }'
```
