export PK="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
export RPC_URL="http://127.0.0.1:8545"
forge script script/CNC.s.sol --rpc-url ${RPC_URL} --private-key ${PK} 
# forge script script/CNC.s.sol --rpc-url ${RPC_URL} --private-key ${PK} --broadcast 