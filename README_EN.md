# FilNote Contract Deployment Guide

## Deploy FilNote Contract

### Build
```bash
forge build
```

### Calibration Testnet Deployment

```bash
forge create src/FilNote.sol:FilNoteContract --rpc-url https://rpc.ankr.com/filecoin_testnet --private-key <PRIVATE_KEY> --broadcast --verify --verifier sourcify -vvvv
```

### Flatten
```bash
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```
