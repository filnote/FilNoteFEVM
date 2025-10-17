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
当前已部署测试网地址：[0xC377AF7CE09A9B874FC5e3a7998d531109d54D34]:(https://filecoin-testnet.blockscout.com/address/0xC377AF7CE09A9B874FC5e3a7998d531109d54D34?tab=read_contract)

### Flatten
```bash
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```