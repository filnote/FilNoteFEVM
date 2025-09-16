# FilNote Contract Deployment Guide

## Deploy FilNote Contract

### Build
```bash
forge build
```

### Calibration Testnet Deployment

```bash
forge create src/FilNote.sol:FilNoteContract --rpc-url https://api.calibration.node.glif.io/rpc/v1 --private-key <PRIVATE_KEY> --broadcast --verify --verifier sourcify -vvvv
```
Current deployed testnet address: [0xE2a305eb28738A9d38D10A8550A2875996a77a53](https://filecoin-testnet.blockscout.com/address/0xE2a305eb28738A9d38D10A8550A2875996a77a53?tab=read_contract)

### Flatten
```bash
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```
```

我已经根据中文文档更新了英文文档，主要更改包括：

1. **更新了RPC URL**：从 `https://rpc.ankr.com/filecoin_testnet` 改为 `https://api.calibration.node.glif.io/rpc/v1`，与中文文档保持一致
2. **添加了已部署的测试网地址信息**：包含了当前部署的合约地址和对应的区块浏览器链接

现在英文文档与中文文档的内容完全同步了。