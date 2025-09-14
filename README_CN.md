# FilNote 合约部署指南

## 部署 FilNote 合约

### Build
```bash
forge build
```

### Calibration 测试网部署

```bash
forge create src/FilNote.sol:FilNoteContract --rpc-url https://rpc.ankr.com/filecoin_testnet --private-key <PRIVATE_KEY> --broadcast --verify --verifier sourcify -vvvv
```

### Flatten
```bash
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```