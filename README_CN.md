# FilNote - Filecoin EVM 上的去中心化投资票据协议

[English Documentation](./README.md)

## 项目概述

FilNote 是一个构建在 Filecoin EVM (FEVM) 上的去中心化投资票据协议。它使用户能够创建、投资和管理投资票据，具有自动利息计算和协议合约管理功能。该系统实现了安全、透明和无需信任的点对点借贷和投资机制。

## 功能特性

- **票据创建**: 创建具有可自定义目标金额、利率和借款期限的投资票据
- **审计员系统**: 多审计员审批系统，用于投资前的票据验证
- **隐私凭证支持**: 支持加密的隐私凭证存储和公开信息预览
- **协议合约**: 为每笔投资自动部署协议合约
- **平台费用**: 可配置的平台费用系统，支持接收者管理
- **生命周期管理**: 从创建到完成/违约的完整票据生命周期
- **安全机制**: 使用 OpenZeppelin 安全库（Ownable, ReentrancyGuard）构建
- **分页支持**: 高效的数据检索，支持大数据集的分页查询

## 架构设计

### 核心合约

1. **FilNoteContract** (`src/FilNote.sol`)

   - 管理投资票据的主合约
   - 处理票据创建、投资和状态管理
   - 管理审计员系统和平台费用

2. **ProtocolsContract** (`src/Protocols.sol`)

   - 为每笔活跃投资部署的协议合约
   - 管理资金池和提现
   - 处理利息计算和到期检查

3. **Types** (`src/utils/Types.sol`)
   - 数据结构和错误定义
   - 票据状态枚举
   - 协议信息结构体

### 票据生命周期

```
INIT → PENDING → ACTIVE → COMPLETED/DEFAULTED
  ↓        ↓
CLOSED   STOP
```

1. **INIT**: 创建者创建票据，等待审计员批准
2. **PENDING**: 审计员批准，包含合同哈希（以及可选的加密隐私凭证哈希和公开预览哈希），开放投资
3. **ACTIVE**: 收到投资，协议合约已部署
4. **COMPLETED**: 成功偿还本金和利息
5. **DEFAULTED**: 未能履行还款义务
6. **CLOSED**: 在投资前被创建者或所有者关闭
7. **STOP**: 在活跃状态下被所有者停止

### 隐私凭证管理

- **加密隐私凭证哈希**: 完整的隐私凭证 IPFS 哈希，使用平台钱包加密，存储在链上
- **隐私凭证摘要哈希**: 隐私凭证的公开预览版本（jsonData），以 JSON 格式存储在 IPFS 上，所有用户可见
- **访问控制**: 完整的隐私凭证只能由票据创建者或投资者在投资后解密查看

## 合约详情

### FilNoteContract

#### 核心函数

- `createNote(uint256 targetAmount, uint16 interestRateBps, uint16 borrowingDays)`: 创建新的投资票据
- `invest(uint64 id)`: 投资待投资票据（可支付函数）
- `pendingNote(uint64 id, string calldata contractHash, string calldata encryptedPrivacyCertificateHash, string calldata privacyCredentialsAbridgedHash)`: 批准票据进行投资（仅审计员）
- `closeNote(uint64 id)`: 关闭票据（创建者或所有者）
- `stopNote(uint64 id)`: 停止活跃票据（仅所有者）
- `completeNote(uint64 id)`: 标记票据为已完成（仅协议合约）
- `defaultNote(uint64 id)`: 标记票据为违约（仅协议合约）

#### 查询函数

- `getNote(uint64 id)`: 根据 ID 获取票据
- `getNotes(uint256 offset, uint256 limit)`: 获取分页票据列表
- `getNoteByIds(uint64[] calldata ids)`: 根据 ID 数组获取多个票据
- `getNotesByCreator(address creator, uint256 offset, uint256 limit)`: 获取创建者的票据
- `getNotesByInvestor(address investor, uint256 offset, uint256 limit)`: 获取投资者的票据
- `getTotalNotes()`: 获取票据总数

#### 管理函数

- `addAuditor(address auditor)`: 添加审计员（仅所有者）
- `removeAuditor(address auditor)`: 移除审计员（仅所有者）
- `setPlatformFee(uint256 platformFee)`: 设置平台费用率（仅所有者）
- `setPlatformFeeRecipient(address platformFeeRecipient)`: 设置费用接收者（仅所有者）

### ProtocolsContract

#### 核心函数

- `withdrawFundingAmount()`: 创建者提取初始资金
- `spWithdrawPoolAmount(uint256 amount)`: 创建者从资金池提取（保留最低储备）
- `investorWithdrawPoolAmount()`: 投资者在到期后提取
- `stopProtocol()`: 停止协议并向投资者返还资金（仅 FilNote 合约）

#### 查询函数

- `getProtocolInfo()`: 获取关联票据信息
- `getContractInfo()`: 获取资金和资金池金额

## 部署指南

### 前置要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js 和 npm/yarn
- 用于部署的私钥

### 编译

```bash
forge build
```

### Calibration 测试网部署

```bash
forge create src/FilNote.sol:FilNoteContract \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify \
  --verifier sourcify \
  -vvvv
```

**当前已部署测试网地址**: [0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30](https://filecoin-testnet.blockscout.com/address/0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30?tab=read_contract)

### 扁平化合约

```bash
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```

## 使用说明

### 创建票据

```solidity
// 创建票据，参数：
// - 目标金额: 1 FIL (1e18 wei)
// - 利率: 5% (500 基点)
// - 借款期限: 30 天
uint64 noteId = filNoteContract.createNote(
    1e18,    // targetAmount
    500,     // interestRateBps (5%)
    30       // borrowingDays
);
```

### 批准票据（审计员）

```solidity
// 使用IPFS合约哈希和可选的隐私凭证批准票据
filNoteContract.pendingNote(
    noteId,
    "QmYourIPFSHashHere",  // contractHash (必填)
    "encryptedHash...",     // encryptedPrivacyCertificateHash (可选)
    "QmPreviewHash..."      // privacyCredentialsAbridgedHash (可选，公开预览)
);
```

### 投资票据

```solidity
// 投资精确的目标金额
filNoteContract.invest{value: 1e18}(noteId);
```

### 提取资金（协议合约）

```solidity
// 创建者提取初始资金
protocolContract.withdrawFundingAmount();

// 创建者从资金池提取（保持最低储备）
protocolContract.spWithdrawPoolAmount(amount);

// 投资者在到期后提取
protocolContract.investorWithdrawPoolAmount();
```

## 安全特性

- **重入保护**: 所有状态更改函数都使用 ReentrancyGuard
- **访问控制**: 关键操作仅限所有者
- **输入验证**: 全面的参数验证
- **安全数学**: 使用 OpenZeppelin 的 Math 库进行计算
- **最低储备**: 协议合约保持最低储备以保护投资者
- **审计员系统**: 多审计员审批机制用于票据验证

## 开发指南

### 项目结构

```
FilNoteFEVM/
├── src/
│   ├── FilNote.sol          # 主合约
│   ├── Protocols.sol        # 协议合约
│   └── utils/
│       └── Types.sol        # 数据结构
├── script/                  # 部署脚本
├── test/                    # 测试文件
├── lib/                     # 依赖库
└── foundry.toml            # Foundry 配置
```

### 依赖项

- OpenZeppelin Contracts (Ownable, ReentrancyGuard, Math)
- Forge Std
- Filecoin Solidity API

### 代码检查

```bash
# 格式化代码
yarn prettier

# 检查格式
yarn prettier:check

# Solidity 代码检查
yarn solhint

# 运行所有检查
yarn lint
```

### 测试

```bash
forge test
```

## 配置说明

### Foundry 配置

项目使用 Foundry，主要配置如下：

- Solidity 版本: `0.8.22`
- 优化器: 启用（200 次运行）
- Via IR: 启用
- 链 ID: 314159 (Calibration 测试网)

完整配置请参见 `foundry.toml`。

## 许可证

MIT 许可证 - 详见 [LICENSE](./LICENSE) 文件。

## 相关链接

- **测试网浏览器**: [Filecoin Calibration Blockscout](https://filecoin-testnet.blockscout.com/)
- **RPC 端点**: https://api.calibration.node.glif.io/rpc/v1
- **Foundry 文档**: https://book.getfoundry.sh/

## 贡献指南

欢迎贡献！请确保所有代码遵循项目的代码检查标准，并包含适当的测试。
