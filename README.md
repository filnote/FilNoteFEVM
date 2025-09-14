# 
## 部署 FilNote 合约
### Buid
`forge build`
### calibration 测试网
`forge script script/DeployFilNote.s.sol:DeployFilNote   --rpc-url https://rpc.ankr.com/filecoin_testnet  --broadcast --gas-estimate-multiplier 2000   -vvvv`
`forge create src/FilNote.sol:FilNoteContract  --rpc-url https://rpc.ankr.com/filecoin_testnet --private-key 0x785d754987ef3c91d6b9a1154f02e439eccd434087cb6dfd530b8c8e21dceecc  --broadcast --verify --verifier sourcify -vvvv`
### flatten
`forge flatten src/FilNote.sol -o flattened/FilNote.sol`
### 验证合约
`forge verify-contract 0x8b52acf547a7e2cc869f0f5b88a95bcbdad4b6f2  flattened/FilNote.sol:FilNoteContract  --chain-id 314159  --rpc-url https://api.calibration.node.glif.io/rpc/v1`