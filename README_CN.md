# FilNote 合约部署指南

## 部署 FilNote 合约

### Build
```bash
forge build
```

### Calibration 测试网部署

```bash
forge create src/FilNote.sol:FilNoteContract --rpc-url https://api.calibration.node.glif.io/rpc/v1 --private-key <PRIVATE_KEY> --broadcast --verify --verifier sourcify -vvvv
```
当前已部署测试网地址：[0xE2a305eb28738A9d38D10A8550A2875996a77a53]:(https://filecoin-testnet.blockscout.com/address/0xE2a305eb28738A9d38D10A8550A2875996a77a53?tab=read_contract)

### Flatten
```bash
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```