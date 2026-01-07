<div align="center">

# 🎯 FilNote

**基于 Filecoin EVM 的去中心化投资票据协议**

[![Solidity](https://img.shields.io/badge/Solidity-0.8.22-blue.svg)](https://soliditylang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://book.getfoundry.sh/)

[English](./README.md) | [中文](./README_CN.md)

</div>

---

## 📋 目录

- [项目概述](#-项目概述)
- [核心功能](#-核心功能)
- [架构设计](#-架构设计)
- [快速开始](#-快速开始)
- [合约详情](#-合约详情)
- [安全特性](#-安全特性)
- [开发指南](#-开发指南)
- [相关仓库](#-相关仓库)

---

## 🎯 项目概述

FilNote 是一个构建在 **Filecoin EVM (FEVM)** 上的去中心化投资票据协议。它使用户能够创建、投资和管理投资票据，具有自动利息计算和协议合约管理功能。该系统实现了安全、透明和无需信任的点对点借贷和投资机制。

### FilNote 是什么？

FilNote 将中心化的 FIL 借贷映射到现实世界资产（RWA），如债务或收益凭证。它提供了完整的投资票据生命周期管理系统，从创建到完成或违约，内置安全功能和审计员验证机制。

---

## ✨ 核心功能

| 功能                | 描述                                                              |
| ------------------- | ----------------------------------------------------------------- |
| 📝 **票据创建**     | 创建具有可自定义目标金额、利率和借款期限的投资票据                |
| ✅ **审计员系统**   | 多审计员审批系统，用于投资前的票据验证                            |
| 🔒 **隐私凭证**     | 加密的隐私凭证存储，通过 IPFS 提供公开信息预览                    |
| 🤖 **协议合约**     | 为每笔活跃投资自动部署协议合约                                    |
| 💰 **平台费用**     | 可配置的平台费用系统（默认 2%），支持接收者管理                   |
| 🔄 **生命周期管理** | 完整的票据生命周期：INIT → PENDING → ACTIVE → COMPLETED/DEFAULTED |
| 🛡️ **安全机制**     | 使用 OpenZeppelin 的成熟库（Ownable, ReentrancyGuard）构建        |
| 📊 **高效查询**     | 支持大数据集的分页查询（每次最多 100 条）                         |

---

## 🏗️ 架构设计

### 系统组件

```
┌─────────────────────────────────────────────────────────────┐
│                    FilNote 生态系统                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   前端应用    │───▶│   后端 API   │───▶│   智能合约   │  │
│  │  (Quasar)    │    │   (NestJS)   │    │              │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                    │                    │          │
│         │                    │                    │          │
│         └────────────────────┴────────────────────┘         │
│                              │                              │
│                              ▼                              │
│                    ┌──────────────┐                        │
│                    │     IPFS     │                        │
│                    │   (Pinata)   │                        │
│                    └──────────────┘                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 核心合约

#### 1. FilNoteContract (`src/FilNote.sol`)

管理整个投资票据生命周期的主合约。

**职责：**

- ✅ 票据创建和验证
- ✅ 投资处理
- ✅ 状态管理（7 种状态）
- ✅ 审计员系统管理
- ✅ 平台费用配置
- ✅ 支持分页的查询函数

**关键指标：**

- 函数总数：20+
- 状态变量：10
- 事件：6
- 修饰符：2

#### 2. ProtocolsContract (`src/Protocols.sol`)

为每笔活跃投资自动部署，用于管理单个票据操作。

**职责：**

- 💰 资金金额管理
- 📊 资金池金额跟踪
- 🧮 利息计算
- ⏰ 到期检查
- 🛑 紧急停止功能

**关键指标：**

- 不可变变量：4
- 状态变量：3
- 函数：6

#### 3. Types (`src/utils/Types.sol`)

共享数据结构和错误定义。

**内容：**

- NoteStatus 枚举（7 种状态）
- Note 结构体（15 个字段）
- ProtocolInfo 结构体
- 15 种自定义错误类型

---

## 🔄 票据生命周期

```
┌──────┐
│ INIT │  ← 创建者创建票据
└──┬───┘
   │
   ├─[审计员批准]─┐
   │              │
   ▼              ▼
┌─────────┐   ┌─────────┐
│ PENDING │   │ CLOSED  │  ← 创建者/所有者关闭
└──┬──────┘   └─────────┘
   │
   ├─[投资]─┐
   │        │
   ▼        ▼
┌─────────┐ ┌─────────┐
│ ACTIVE  │ │  STOP   │  ← 所有者停止
└──┬──────┘ └─────────┘
   │
   ├─[还款]─┐
   │        │
   ▼        ▼
┌──────────┐ ┌──────────┐
│COMPLETED │ │DEFAULTED │
└──────────┘ └──────────┘
```

### 状态说明

| 状态          | 描述                       | 触发者        |
| ------------- | -------------------------- | ------------- |
| **INIT**      | 票据已创建，等待审计员批准 | 创建者        |
| **PENDING**   | 审计员已批准，开放投资     | 审计员        |
| **ACTIVE**    | 已收到投资，协议合约已部署 | 投资者        |
| **COMPLETED** | 成功偿还本金和利息         | 协议合约      |
| **DEFAULTED** | 未能履行还款义务           | 协议合约      |
| **CLOSED**    | 投资前被关闭               | 创建者/所有者 |
| **STOP**      | 活跃状态下被停止，资金返还 | 所有者        |

---

## 🚀 快速开始

### 前置要求

- [Foundry](https://book.getfoundry.sh/getting-started/installation)（最新版本）
- Node.js 18+ 和 npm/yarn
- 用于部署的私钥（请妥善保管！）

### 安装

```bash
# 克隆仓库
git clone https://github.com/filnote/FilNoteFEVM.git
cd FilNoteFEVM

# 安装依赖
forge install

# 编译合约
forge build
```

### 部署

#### Calibration 测试网

```bash
forge create src/FilNote.sol:FilNoteContract \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify \
  --verifier sourcify \
  -vvvv
```

**已部署地址**: [`0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30`](https://filecoin-testnet.blockscout.com/address/0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30?tab=read_contract)

---

## 📖 合约详情

### FilNoteContract 函数

#### 核心操作

| 函数                      | 描述                   | 访问权限       |
| ------------------------- | ---------------------- | -------------- |
| `createNote(...)`         | 创建新的投资票据       | 公开           |
| `invest(uint64 id)`       | 投资待投资票据         | 公开（可支付） |
| `pendingNote(...)`        | 批准票据进行投资       | 仅审计员       |
| `closeNote(uint64 id)`    | 在投资前关闭票据       | 创建者/所有者  |
| `stopNote(uint64 id)`     | 停止活跃票据，返还资金 | 仅所有者       |
| `completeNote(uint64 id)` | 标记票据为已完成       | 协议合约       |
| `defaultNote(uint64 id)`  | 标记票据为违约         | 协议合约       |

#### 查询函数

| 函数                         | 描述                     | 返回值         |
| ---------------------------- | ------------------------ | -------------- |
| `getNote(uint64 id)`         | 根据 ID 获取票据         | `Types.Note`   |
| `getNotes(offset, limit)`    | 获取分页票据列表         | `Types.Note[]` |
| `getNoteByIds(uint64[] ids)` | 根据 ID 数组获取多个票据 | `Types.Note[]` |
| `getNotesByCreator(...)`     | 获取创建者的票据         | `uint64[]`     |
| `getNotesByInvestor(...)`    | 获取投资者的票据         | `uint64[]`     |
| `getTotalNotes()`            | 获取票据总数             | `uint256`      |

#### 管理函数

| 函数                               | 描述           | 访问权限 |
| ---------------------------------- | -------------- | -------- |
| `addAuditor(address)`              | 添加审计员     | 仅所有者 |
| `removeAuditor(address)`           | 移除审计员     | 仅所有者 |
| `setPlatformFee(uint256)`          | 设置平台费用率 | 仅所有者 |
| `setPlatformFeeRecipient(address)` | 设置费用接收者 | 仅所有者 |

### ProtocolsContract 函数

| 函数                            | 描述               | 访问权限        |
| ------------------------------- | ------------------ | --------------- |
| `withdrawFundingAmount()`       | 创建者提取初始资金 | 仅创建者        |
| `spWithdrawPoolAmount(uint256)` | 创建者从资金池提取 | 仅创建者        |
| `investorWithdrawPoolAmount()`  | 投资者在到期后提取 | 仅投资者        |
| `stopProtocol()`                | 停止并返还所有资金 | 仅 FilNote 合约 |

---

## 🔐 安全特性

### 已实现的安全措施

| 安全特性       | 实现方式                             | 状态 |
| -------------- | ------------------------------------ | ---- |
| **重入保护**   | 所有状态更改函数使用 ReentrancyGuard | ✅   |
| **访问控制**   | Ownable 用于仅所有者函数             | ✅   |
| **输入验证**   | 全面的参数检查                       | ✅   |
| **安全数学**   | OpenZeppelin Math 库                 | ✅   |
| **最低储备**   | 协议合约保持储备                     | ✅   |
| **审计员验证** | 多审计员审批系统                     | ✅   |
| **金额限制**   | MAX_TARGET_AMOUNT 常量（10 亿 FIL）  | ✅   |
| **Gas 优化**   | O(1) 审计员查询，高效存储            | ✅   |

### 安全最佳实践

- ✅ 所有外部调用使用 `call{value}()` 并处理错误
- ✅ 状态更改遵循检查-效果-交互模式
- ✅ 使用自定义错误实现高效的 Gas 回滚
- ✅ 尽可能使用不可变变量
- ✅ 所有重要状态更改都发出事件

---

## 💻 开发指南

### 项目结构

```
FilNoteFEVM/
├── src/
│   ├── FilNote.sol          # 主合约 (575 行)
│   ├── Protocols.sol         # 协议合约 (168 行)
│   └── utils/
│       └── Types.sol         # 数据结构和错误
├── script/                   # 部署脚本
├── test/                     # 测试文件
├── lib/                      # 依赖库
│   ├── openzeppelin-contracts/
│   ├── forge-std/
│   └── filecoin-solidity-api/
├── out/                      # 构建产物
├── foundry.toml              # Foundry 配置
└── package.json              # Node.js 依赖
```

### 技术栈

| 组件       | 技术         | 版本             |
| ---------- | ------------ | ---------------- |
| **语言**   | Solidity     | ^0.8.22          |
| **框架**   | Foundry      | 最新版           |
| **安全库** | OpenZeppelin | v5.x             |
| **网络**   | Filecoin EVM | Calibration/主网 |

### 开发命令

```bash
# 编译合约
forge build

# 运行测试
forge test

# 格式化代码
yarn prettier

# Solidity 代码检查
yarn solhint

# 运行所有检查
yarn lint

# 扁平化合约
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```

### 配置

**Foundry 设置** (`foundry.toml`):

- Solidity 版本: `0.8.22`
- 优化器: 启用（200 次运行）
- Via IR: 启用
- 链 ID: 314159 (Calibration 测试网)

---

## 📚 使用示例

### 创建票据

```solidity
// 创建票据，参数：
// - 目标金额: 1 FIL
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
// 使用 IPFS 哈希批准票据
filNoteContract.pendingNote(
    noteId,
    "QmYourIPFSHashHere",      // contractHash (必填)
    "encryptedHash...",         // encryptedPrivacyCertificateHash (可选)
    "QmPreviewHash..."          // privacyCredentialsAbridgedHash (可选)
);
```

### 投资票据

```solidity
// 投资精确的目标金额
filNoteContract.invest{value: 1e18}(noteId);
```

### 提取资金

```solidity
// 创建者提取初始资金
protocolContract.withdrawFundingAmount();

// 创建者从资金池提取（保持最低储备）
protocolContract.spWithdrawPoolAmount(amount);

// 投资者在到期后提取
protocolContract.investorWithdrawPoolAmount();
```

---

## 🗓️ 开发历程

FilNote 经过四个主要阶段的开发：

| 阶段         | 时间          | 重点                |
| ------------ | ------------- | ------------------- |
| **第一阶段** | 2025 年 9 月  | 核心合约设计和实现  |
| **第二阶段** | 2025 年 10 月 | 前端界面 v1.0       |
| **第三阶段** | 2025 年 11 月 | 审计员功能          |
| **第四阶段** | 2025 年 12 月 | IPFS 集成与风险信息 |

📖 **详细时间线**: 参见 [DEVELOPMENT_TIMELINE_CN.md](./DEVELOPMENT_TIMELINE_CN.md)

---

## 🔗 相关仓库

| 仓库                                                                | 描述          | 技术栈                      |
| ------------------------------------------------------------------- | ------------- | --------------------------- |
| [**FilNoteFEVMFront**](https://github.com/filnote/FilNoteFEVMFront) | 前端应用      | Quasar (Vue 3 + TypeScript) |
| [**FilNoteFEVMAPI**](https://github.com/filnote/FilNoteFEVMAPI)     | 后端 API 服务 | NestJS + TypeScript         |

---

## 🔗 相关链接

| 资源             | 链接                                                                        |
| ---------------- | --------------------------------------------------------------------------- |
| **测试网浏览器** | [Filecoin Calibration Blockscout](https://filecoin-testnet.blockscout.com/) |
| **RPC 端点**     | `https://api.calibration.node.glif.io/rpc/v1`                               |
| **Foundry 文档** | [book.getfoundry.sh](https://book.getfoundry.sh/)                           |
| **OpenZeppelin** | [docs.openzeppelin.com](https://docs.openzeppelin.com/)                     |

---

## 📄 许可证

本项目采用 **MIT 许可证** - 详见 [LICENSE](./LICENSE) 文件。

---

## 🤝 贡献指南

欢迎贡献！请确保：

- ✅ 代码遵循项目代码检查标准
- ✅ 所有函数包含适当的测试
- ✅ 文档已更新
- ✅ 遵循安全最佳实践

---

<div align="center">

**基于 Filecoin EVM 构建，用心打造 ❤️**

[⬆ 返回顶部](#-filnote)

</div>
