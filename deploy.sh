# export PK=
# export RPC_URL=
forge script script/CNC.s.sol --rpc-url ${RPC_URL} --private-key ${PK}  -vvvv \
    --broadcast \
    --etherscan-api-key $API_KEY \
    --verify