<div align="center">

# 🎯 FilNote

**Decentralized Investment Note Protocol on Filecoin EVM**

[![Solidity](https://img.shields.io/badge/Solidity-0.8.22-blue.svg)](https://soliditylang.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-000000.svg)](https://book.getfoundry.sh/)

[English](./README.md) | [中文](./README_CN.md)

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Quick Start](#-quick-start)
- [Contract Details](#-contract-details)
- [Security](#-security)
- [Development](#-development)
- [Related Repositories](#-related-repositories)

---

## 🎯 Overview

FilNote is a decentralized investment note protocol built on **Filecoin EVM (FEVM)**. It enables users to create, invest in, and manage investment notes with automated interest calculations and protocol contract management. The system implements a secure, transparent, and trustless mechanism for peer-to-peer lending and investment.

### What is FilNote?

FilNote maps centralized FIL lending into real-world assets (RWA) like debt or income certificates. It provides a complete lifecycle management system for investment notes, from creation to completion or default, with built-in security features and auditor verification.

---

## ✨ Key Features

| Feature                     | Description                                                                                     |
| --------------------------- | ----------------------------------------------------------------------------------------------- |
| 📝 **Note Creation**        | Create investment notes with customizable target amounts, interest rates, and borrowing periods |
| ✅ **Auditor System**       | Multi-auditor approval system for note verification before investment                           |
| 🔒 **Privacy Certificates** | Encrypted privacy certificate storage with public information preview via IPFS                  |
| 🤖 **Protocol Contracts**   | Automated protocol contract deployment for each active investment                               |
| 💰 **Platform Fees**        | Configurable platform fee system (default 2%) with recipient management                         |
| 🔄 **Lifecycle Management** | Complete note lifecycle: INIT → PENDING → ACTIVE → COMPLETED/DEFAULTED                          |
| 🛡️ **Security**             | Built with OpenZeppelin's battle-tested libraries (Ownable, ReentrancyGuard)                    |
| 📊 **Efficient Queries**    | Pagination support for large datasets (max 100 items per query)                                 |

---

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    FilNote Ecosystem                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Frontend   │───▶│  Backend API │───▶│   Smart      │  │
│  │  (Quasar)    │    │   (NestJS)   │    │  Contracts   │  │
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

### Core Contracts

#### 1. FilNoteContract (`src/FilNote.sol`)

The main contract managing the entire investment note lifecycle.

**Responsibilities:**

- ✅ Note creation and validation
- ✅ Investment processing
- ✅ Status management (7 states)
- ✅ Auditor system management
- ✅ Platform fee configuration
- ✅ Query functions with pagination

**Key Metrics:**

- Total Functions: 20+
- State Variables: 10
- Events: 6
- Modifiers: 2

#### 2. ProtocolsContract (`src/Protocols.sol`)

Deployed automatically for each active investment to manage individual note operations.

**Responsibilities:**

- 💰 Funding amount management
- 📊 Pool amount tracking
- 🧮 Interest calculations
- ⏰ Maturity checks
- 🛑 Emergency stop functionality

**Key Metrics:**

- Immutable Variables: 4
- State Variables: 3
- Functions: 6

#### 3. Types (`src/utils/Types.sol`)

Shared data structures and error definitions.

**Contents:**

- NoteStatus enum (7 states)
- Note struct (15 fields)
- ProtocolInfo struct
- 15 custom error types

---

## 🔄 Note Lifecycle

```
┌──────┐
│ INIT │  ← Note created by creator
└──┬───┘
   │
   ├─[Auditor Approval]─┐
   │                     │
   ▼                     ▼
┌─────────┐         ┌─────────┐
│ PENDING │         │ CLOSED  │  ← Closed by creator/owner
└──┬──────┘         └─────────┘
   │
   ├─[Investment]─┐
   │              │
   ▼              ▼
┌─────────┐   ┌─────────┐
│ ACTIVE  │   │  STOP   │  ← Stopped by owner
└──┬──────┘   └─────────┘
   │
   ├─[Repayment]─┐
   │             │
   ▼             ▼
┌──────────┐  ┌──────────┐
│COMPLETED │  │DEFAULTED │
└──────────┘  └──────────┘
```

### Status Descriptions

| Status        | Description                                     | Who Can Trigger   |
| ------------- | ----------------------------------------------- | ----------------- |
| **INIT**      | Note created, awaiting auditor approval         | Creator           |
| **PENDING**   | Approved by auditor, open for investment        | Auditor           |
| **ACTIVE**    | Investment received, protocol contract deployed | Investor          |
| **COMPLETED** | Successfully repaid with interest               | Protocol Contract |
| **DEFAULTED** | Failed to meet repayment obligations            | Protocol Contract |
| **CLOSED**    | Closed before investment                        | Creator/Owner     |
| **STOP**      | Stopped during active state, funds returned     | Owner             |

---

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (latest version)
- Node.js 18+ and npm/yarn
- Private key for deployment (keep secure!)

### Installation

```bash
# Clone the repository
git clone https://github.com/filnote/FilNoteFEVM.git
cd FilNoteFEVM

# Install dependencies
forge install

# Build contracts
forge build
```

### Deployment

#### Calibration Testnet

```bash
forge create src/FilNote.sol:FilNoteContract \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify \
  --verifier sourcify \
  -vvvv
```

**Deployed Address**: [`0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30`](https://filecoin-testnet.blockscout.com/address/0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30?tab=read_contract)

#### Filecoin Mainnet

```bash
forge create src/FilNote.sol:FilNoteContract \
  --rpc-url https://api.node.glif.io/rpc/v1 \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify \
  --verifier sourcify \
  -vvvv
```

**Deployed Address**: [`0x13C547f76E9C979e160125Fe9dfA84Df0d547c1E`](https://filfox.info/en/address/0x13C547f76E9C979e160125Fe9dfA84Df0d547c1E)

---

## 📖 Contract Details

### FilNoteContract Functions

#### Core Operations

| Function                  | Description                    | Access            |
| ------------------------- | ------------------------------ | ----------------- |
| `createNote(...)`         | Create a new investment note   | Public            |
| `invest(uint64 id)`       | Invest in a pending note       | Public (payable)  |
| `pendingNote(...)`        | Approve note for investment    | Auditor only      |
| `closeNote(uint64 id)`    | Close a note before investment | Creator/Owner     |
| `stopNote(uint64 id)`     | Stop active note, return funds | Owner only        |
| `completeNote(uint64 id)` | Mark note as completed         | Protocol Contract |
| `defaultNote(uint64 id)`  | Mark note as defaulted         | Protocol Contract |

#### Query Functions

| Function                     | Description          | Returns        |
| ---------------------------- | -------------------- | -------------- |
| `getNote(uint64 id)`         | Get note by ID       | `Types.Note`   |
| `getNotes(offset, limit)`    | Get paginated notes  | `Types.Note[]` |
| `getNoteByIds(uint64[] ids)` | Get multiple notes   | `Types.Note[]` |
| `getNotesByCreator(...)`     | Get creator's notes  | `uint64[]`     |
| `getNotesByInvestor(...)`    | Get investor's notes | `uint64[]`     |
| `getTotalNotes()`            | Get total note count | `uint256`      |

#### Admin Functions

| Function                           | Description           | Access     |
| ---------------------------------- | --------------------- | ---------- |
| `addAuditor(address)`              | Add an auditor        | Owner only |
| `removeAuditor(address)`           | Remove an auditor     | Owner only |
| `setPlatformFee(uint256)`          | Set platform fee rate | Owner only |
| `setPlatformFeeRecipient(address)` | Set fee recipient     | Owner only |

### ProtocolsContract Functions

| Function                        | Description                       | Access                |
| ------------------------------- | --------------------------------- | --------------------- |
| `withdrawFundingAmount()`       | Creator withdraws initial funding | Creator only          |
| `spWithdrawPoolAmount(uint256)` | Creator withdraws from pool       | Creator only          |
| `investorWithdrawPoolAmount()`  | Investor withdraws after maturity | Investor only         |
| `stopProtocol()`                | Stop and return all funds         | FilNote Contract only |

---

## 🔐 Security Features

### Implemented Protections

| Security Feature          | Implementation                                  | Status |
| ------------------------- | ----------------------------------------------- | ------ |
| **Reentrancy Protection** | ReentrancyGuard on all state-changing functions | ✅     |
| **Access Control**        | Ownable for owner-only functions                | ✅     |
| **Input Validation**      | Comprehensive parameter checks                  | ✅     |
| **Safe Math**             | OpenZeppelin Math library                       | ✅     |
| **Minimum Reserve**       | Protocol contracts maintain reserves            | ✅     |
| **Auditor Verification**  | Multi-auditor approval system                   | ✅     |
| **Amount Limits**         | MAX_TARGET_AMOUNT constant (1B FIL)             | ✅     |
| **Gas Optimization**      | O(1) auditor lookup, efficient storage          | ✅     |

### Security Best Practices

- ✅ All external calls use `call{value}()` with error handling
- ✅ State changes follow Check-Effects-Interactions pattern
- ✅ Custom errors for gas-efficient reverts
- ✅ Immutable variables where possible
- ✅ Events for all important state changes

---

## 💻 Development

### Project Structure

```
FilNoteFEVM/
├── src/
│   ├── FilNote.sol          # Main contract (575 lines)
│   ├── Protocols.sol         # Protocol contract (168 lines)
│   └── utils/
│       └── Types.sol         # Data structures & errors
├── script/                   # Deployment scripts
├── test/                     # Test files
├── lib/                      # Dependencies
│   ├── openzeppelin-contracts/
│   ├── forge-std/
│   └── filecoin-solidity-api/
├── out/                      # Build artifacts
├── foundry.toml              # Foundry configuration
└── package.json              # Node.js dependencies
```

### Technology Stack

| Component     | Technology   | Version             |
| ------------- | ------------ | ------------------- |
| **Language**  | Solidity     | ^0.8.22             |
| **Framework** | Foundry      | Latest              |
| **Security**  | OpenZeppelin | v5.x                |
| **Network**   | Filecoin EVM | Calibration/Mainnet |

### Development Commands

```bash
# Build contracts
forge build

# Run tests
forge test

# Format code
yarn prettier

# Lint Solidity
yarn solhint

# Run all checks
yarn lint

# Flatten contract
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```

### Configuration

**Foundry Settings** (`foundry.toml`):

- Solidity version: `0.8.22`
- Optimizer: Enabled (200 runs)
- Via IR: Enabled
- Chain ID: 314159 (Calibration testnet)

---

## 📚 Usage Examples

### Creating a Note

```solidity
// Create a note with:
// - Target amount: 1 FIL
// - Interest rate: 5% (500 basis points)
// - Borrowing period: 30 days
uint64 noteId = filNoteContract.createNote(
    1e18,    // targetAmount
    500,     // interestRateBps (5%)
    30       // borrowingDays
);
```

### Approving a Note (Auditor)

```solidity
// Approve note with IPFS hashes
filNoteContract.pendingNote(
    noteId,
    "QmYourIPFSHashHere",      // contractHash (required)
    "encryptedHash...",         // encryptedPrivacyCertificateHash (optional)
    "QmPreviewHash..."          // privacyCredentialsAbridgedHash (optional)
);
```

### Investing in a Note

```solidity
// Invest exact target amount
filNoteContract.invest{value: 1e18}(noteId);
```

### Withdrawing Funds

```solidity
// Creator withdraws initial funding
protocolContract.withdrawFundingAmount();

// Creator withdraws from pool (maintains minimum reserve)
protocolContract.spWithdrawPoolAmount(amount);

// Investor withdraws after maturity
protocolContract.investorWithdrawPoolAmount();
```

---

## 🗓️ Development Timeline

FilNote has been developed through four major phases:

| Phase       | Period         | Focus                                   |
| ----------- | -------------- | --------------------------------------- |
| **Phase 1** | September 2025 | Core contract design and implementation |
| **Phase 2** | October 2025   | Frontend interface v1.0                 |
| **Phase 3** | November 2025  | Auditor functionality                   |
| **Phase 4** | December 2025  | IPFS integration & risk information     |

📖 **Detailed Timeline**: See [DEVELOPMENT_TIMELINE.md](./DEVELOPMENT_TIMELINE.md)

---

## 🔗 Related Repositories

| Repository                                                          | Description          | Tech Stack                  |
| ------------------------------------------------------------------- | -------------------- | --------------------------- |
| [**FilNoteFEVMFront**](https://github.com/filnote/FilNoteFEVMFront) | Frontend application | Quasar (Vue 3 + TypeScript) |
| [**FilNoteFEVMAPI**](https://github.com/filnote/FilNoteFEVMAPI)     | Backend API service  | NestJS + TypeScript         |

---

## 🔗 Useful Links

| Resource             | Link                                                                        |
| -------------------- | --------------------------------------------------------------------------- |
| **Testnet Explorer** | [Filecoin Calibration Blockscout](https://filecoin-testnet.blockscout.com/) |
| **RPC Endpoint**     | `https://api.calibration.node.glif.io/rpc/v1`                               |
| **Foundry Docs**     | [book.getfoundry.sh](https://book.getfoundry.sh/)                           |
| **OpenZeppelin**     | [docs.openzeppelin.com](https://docs.openzeppelin.com/)                     |

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](./LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please ensure:

- ✅ Code follows project linting standards
- ✅ All functions include appropriate tests
- ✅ Documentation is updated
- ✅ Security best practices are followed

---

<div align="center">

**Built with ❤️ on Filecoin EVM**

[⬆ Back to Top](#-filnote)

</div>
