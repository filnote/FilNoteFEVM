<div align="center">

# 📅 FilNote Development Timeline

**A comprehensive journey from concept to production**

[![Status](https://img.shields.io/badge/Status-Active%20Development-brightgreen.svg)]()
[![Version](https://img.shields.io/badge/Version-1.0-blue.svg)]()
[![Network](https://img.shields.io/badge/Network-Filecoin%20EVM-orange.svg)]()

</div>

---

## 📊 Project Overview

FilNote is a decentralized investment note management platform built on **Filecoin EVM**, enabling creators to issue investment notes, investors to participate in funding, and auditors to review and approve investment opportunities. The platform integrates **IPFS** for permanent storage of risk information and privacy certificates.

### Project Statistics

| Metric                     | Value                                  |
| -------------------------- | -------------------------------------- |
| **Total Development Time** | 4 months (Sep - Dec 2025)              |
| **Smart Contract Lines**   | ~750 lines                             |
| **Core Contracts**         | 2 (FilNoteContract, ProtocolsContract) |
| **Frontend Components**    | 11+ Vue components                     |
| **Backend Services**       | 5+ NestJS modules                      |
| **Git Commits**            | 23+ commits                            |
| **Status**                 | Active Development                     |

---

## 🗓️ Development Phases

```
┌─────────────────────────────────────────────────────────────┐
│                    Development Timeline                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Sep 2025          Oct 2025          Nov 2025    Dec 2025  │
│     │                 │                 │            │      │
│     ▼                 ▼                 ▼            ▼      │
│  ┌────────┐      ┌────────┐      ┌────────┐   ┌────────┐  │
│  │ Phase 1 │─────▶│ Phase 2 │─────▶│ Phase 3 │──▶│ Phase 4 │  │
│  │ Core   │      │Frontend │      │Auditor │   │  IPFS  │  │
│  │Contract│      │   v1.0  │      │Feature │   │Integration│ │
│  └────────┘      └────────┘      └────────┘   └────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Phase 1: Core Contract Design

**Period**: September 2025  
**Duration**: 1 month  
**Focus**: Smart contract foundation

### 📋 Objectives

Establish the foundational smart contract architecture with core investment note functionality, platform review mechanisms, and investor participation features.

### 🎯 Key Deliverables

#### Smart Contract Architecture

| Contract                  | Lines | Functions | Purpose                                     |
| ------------------------- | ----- | --------- | ------------------------------------------- |
| **FilNoteContract.sol**   | 575   | 20+       | Main contract for note lifecycle management |
| **ProtocolsContract.sol** | 168   | 6         | Individual investment protocol management   |
| **Types.sol**             | 155   | -         | Data structures and error definitions       |

#### Core Features Implemented

| Feature                   | Implementation                           | Status |
| ------------------------- | ---------------------------------------- | ------ |
| **Note Creation**         | `createNote()` with validation           | ✅     |
| **Investment Processing** | `invest()` with auto protocol deployment | ✅     |
| **Status Management**     | 7-state lifecycle system                 | ✅     |
| **Platform Fees**         | Configurable fee system (default 2%)     | ✅     |
| **Query Functions**       | Pagination support (max 100 items)       | ✅     |
| **Security**              | OpenZeppelin Ownable + ReentrancyGuard   | ✅     |

#### Technical Specifications

```yaml
Solidity Version: ^0.8.22
Framework: Foundry
Dependencies:
  - OpenZeppelin Contracts: v5.x
  - Forge Std: Latest
  - Filecoin Solidity API: ^1.1.3
Network: Filecoin EVM (Calibration testnet)
Optimizer: Enabled (200 runs)
Via IR: Enabled
```

#### Development Milestones

| Week       | Focus              | Deliverables                   |
| ---------- | ------------------ | ------------------------------ |
| **Week 1** | Initial structure  | Contract skeleton, basic types |
| **Week 2** | Core functionality | Note creation, investment flow |
| **Week 3** | Protocol contracts | Individual protocol management |
| **Week 4** | Security & testing | Security hardening, deployment |

#### Git Commits

- `4ad4a68` - Initial deployment
- `bc44a82` - Contract modifications
- `7285cfa`, `591a86f` - Gas optimizations

#### Key Achievements

- ✅ Complete note lifecycle management
- ✅ Automatic protocol contract deployment
- ✅ Comprehensive input validation
- ✅ Gas-optimized query functions
- ✅ Security best practices implementation

---

## 🎨 Phase 2: Frontend Interface v1.0

**Period**: October 2025  
**Duration**: 1 month  
**Focus**: User interface development

### 📋 Objectives

Develop the first version of the user-facing web application with core interaction capabilities for note creation, browsing, and investment.

### 🎯 Key Deliverables

#### Frontend Architecture

| Component            | Technology                  | Purpose              |
| -------------------- | --------------------------- | -------------------- |
| **Framework**        | Quasar (Vue 3 + TypeScript) | UI framework         |
| **State Management** | Pinia                       | Application state    |
| **Blockchain**       | Filecoin AppKit             | Wallet integration   |
| **Styling**          | Tailwind CSS + Quasar       | UI styling           |
| **i18n**             | Vue I18n                    | Internationalization |

#### Core Components

| Component                   | Purpose                  | Lines |
| --------------------------- | ------------------------ | ----- |
| `CreateNote.vue`            | Note creation form       | ~100  |
| `NoteItem.vue`              | Note card display        | ~80   |
| `InvestmentRecognition.vue` | Investment interface     | ~120  |
| `ReviewNote.vue`            | Auditor review interface | ~150  |
| `ConnectingWallets.vue`     | Wallet connection        | ~60   |
| `WriteContract.vue`         | Generic write operations | ~90   |
| `ReadContract.vue`          | Generic read operations  | ~70   |
| `AgreementDetails.vue`      | Note details view        | ~200  |
| `NoteCountdown.vue`         | Expiry countdown         | ~50   |

#### Features Implemented

| Feature                  | Description                     | Status |
| ------------------------ | ------------------------------- | ------ |
| **Wallet Integration**   | Multi-wallet support via AppKit | ✅     |
| **Note Creation UI**     | Form with validation            | ✅     |
| **Note Browsing**        | List view with pagination       | ✅     |
| **Investment Flow**      | Risk disclosure + investment    | ✅     |
| **Status Indicators**    | Visual status representation    | ✅     |
| **Responsive Design**    | Mobile-friendly layouts         | ✅     |
| **Internationalization** | English & Chinese support       | ✅     |

#### Development Milestones

| Week       | Focus                | Deliverables                          |
| ---------- | -------------------- | ------------------------------------- |
| **Week 1** | Component structure  | Core components, routing              |
| **Week 2** | Wallet integration   | AppKit integration, connection flow   |
| **Week 3** | Contract interaction | Write/Read components, error handling |
| **Week 4** | UI polish            | Styling, animations, user feedback    |

#### Git Commits

- `1779ae9`, `d0cb6ac` - Frontend optimizations
- `338168c`, `9ffcb46` - UI modifications
- `1e3577f`, `8742991` - Bug fixes
- `da8cbc5` - Feature additions
- `892ced8`, `7de93bd` - UI enhancements

#### Key Achievements

- ✅ Complete user interface for all operations
- ✅ Seamless wallet integration
- ✅ Intuitive user experience
- ✅ Responsive design
- ✅ Multi-language support

---

## 👥 Phase 3: Auditor Functionality

**Period**: November 2025  
**Duration**: 1 month  
**Focus**: Auditor role and review workflow

### 📋 Objectives

Implement comprehensive auditor role management and note review workflow to ensure investment quality and compliance.

### 🎯 Key Deliverables

#### Auditor Management System

| Feature                 | Implementation                    | Impact                     |
| ----------------------- | --------------------------------- | -------------------------- |
| **Role Control**        | `addAuditor()`, `removeAuditor()` | Owner-managed auditor list |
| **Access Control**      | `onlyAuditor` modifier            | Restricted note approval   |
| **Lookup Optimization** | Mapping-based O(1) lookup         | Gas savings: ~90-99%       |
| **Review Workflow**     | `pendingNote()` function          | Status transition control  |

#### Gas Optimization Results

| Auditor Count | Before (Gas) | After (Gas) | Savings |
| ------------- | ------------ | ----------- | ------- |
| 10            | ~21,000      | ~2,100      | 90%     |
| 50            | ~97,000      | ~2,100      | 98%     |
| 100           | ~192,000     | ~2,100      | 99%     |

#### Backend Enhancements

| Service             | Purpose                        | Status |
| ------------------- | ------------------------------ | ------ |
| `auditor.guard.ts`  | Signature-based authentication | ✅     |
| `verify.service.ts` | File upload handling           | ✅     |
| Auditor routes      | Protected API endpoints        | ✅     |

#### Frontend Components

| Component          | Purpose           | Status |
| ------------------ | ----------------- | ------ |
| `ReviewNote.vue`   | Auditor dashboard | ✅     |
| Auditor navigation | Role-based UI     | ✅     |
| Permission checks  | Access control UI | ✅     |

#### Security Improvements

| Improvement             | Description                                | Status |
| ----------------------- | ------------------------------------------ | ------ |
| **Arithmetic Overflow** | Fixed potential overflow in calculations   | ✅     |
| **Input Validation**    | Enhanced validation for auditor operations | ✅     |
| **Access Control**      | Multi-layer permission checks              | ✅     |

#### Development Milestones

| Week       | Focus                   | Deliverables                         |
| ---------- | ----------------------- | ------------------------------------ |
| **Week 1** | Auditor role management | Smart contract functions             |
| **Week 2** | Review workflow         | Backend API, frontend UI             |
| **Week 3** | Security fixes          | Overflow protection, optimizations   |
| **Week 4** | Testing & polish        | Integration testing, UI improvements |

#### Git Commits

- `7d5f848` - Arithmetic overflow bug fix
- Multiple commits for auditor feature implementation

#### Key Achievements

- ✅ Complete auditor role management
- ✅ Efficient O(1) auditor lookup
- ✅ Secure review workflow
- ✅ Gas optimization (90-99% savings)
- ✅ Comprehensive access control

---

## 📦 Phase 4: IPFS Integration & Risk Information

**Period**: December 2025  
**Duration**: 1 month  
**Focus**: Permanent storage and privacy management

### 📋 Objectives

Implement permanent storage of risk information and privacy certificates on IPFS, with blockchain-based verification and access control.

### 🎯 Key Deliverables

#### IPFS Storage Integration

| Service                | Purpose                               | Status |
| ---------------------- | ------------------------------------- | ------ |
| **Pinata Service**     | IPFS file upload via API              | ✅     |
| **File Upload**        | Contract & privacy certificate upload | ✅     |
| **Encryption Service** | Privacy certificate encryption        | ✅     |
| **Access Control**     | Investment-based decryption           | ✅     |

#### Smart Contract Enhancements

| Field                            | Type   | Purpose                                 |
| -------------------------------- | ------ | --------------------------------------- |
| `contractHash`                   | string | IPFS CID of contract (required, public) |
| `privacyCertificateHash`         | string | Encrypted IPFS CID (optional)           |
| `privacyCredentialsAbridgedHash` | string | Public preview JSON (optional)          |

#### Data Access Model

```
┌─────────────────────────────────────────┐
│         Information Access              │
├─────────────────────────────────────────┤
│                                         │
│  Public (No Investment Required):        │
│  ├─ Contract Hash (IPFS)                │
│  ├─ Abridged Credentials (JSON)         │
│  └─ Basic Note Information              │
│                                         │
│  Private (Investment Required):         │
│  ├─ Encrypted Privacy Certificate      │
│  ├─ Full Risk Assessment                │
│  └─ Complete Financial Information      │
│                                         │
└─────────────────────────────────────────┘
```

#### Backend API Features

| Endpoint                | Purpose                        | Status |
| ----------------------- | ------------------------------ | ------ |
| `POST /verify/upload`   | File upload to IPFS            | ✅     |
| `POST /encrypt/decrypt` | Privacy certificate decryption | ✅     |
| Signature verification  | Address-based authentication   | ✅     |
| Database integration    | Temporary storage (LowDB)      | ✅     |

#### Frontend Enhancements

| Feature            | Description                   | Status |
| ------------------ | ----------------------------- | ------ |
| **File Upload**    | Drag-and-drop interface       | ✅     |
| **IPFS Links**     | Contract document viewing     | ✅     |
| **Access Control** | Public/private information UI | ✅     |
| **Risk Preview**   | Abridged credentials display  | ✅     |

#### Permanent Storage Benefits

| Benefit              | Description                              |
| -------------------- | ---------------------------------------- |
| **Immutability**     | All documents permanently stored on IPFS |
| **Decentralization** | Distributed across Filecoin network      |
| **Transparency**     | Public contract verification             |
| **Audit Trail**      | Permanent record of all terms            |

#### Development Milestones

| Week       | Focus              | Deliverables                     |
| ---------- | ------------------ | -------------------------------- |
| **Week 1** | IPFS integration   | Pinata service, file upload      |
| **Week 2** | Encryption service | Privacy certificate encryption   |
| **Week 3** | Access control     | Investment-based decryption      |
| **Week 4** | UI integration     | File upload UI, document viewing |

#### Git Commits

- `79230df` - Remove privacyCertificateHash from createNote
- `a806316` - ABI updates for new contract features
- `847c64d` - Contract address and documentation updates
- `009f55a` - Privacy certificate management documentation
- `c3064d2` - STOP status documentation fixes

#### Key Achievements

- ✅ Complete IPFS integration
- ✅ Encrypted privacy certificate management
- ✅ Public preview information system
- ✅ Investment-based access control
- ✅ Permanent document storage

---

## 📈 Project Statistics

### Code Metrics

| Metric                   | Value |
| ------------------------ | ----- |
| **Total Solidity Lines** | ~750  |
| **Total Functions**      | 30+   |
| **Total Events**         | 8     |
| **Custom Errors**        | 15    |
| **State Variables**      | 13    |
| **Frontend Components**  | 11+   |
| **Backend Services**     | 5+    |

### Development Timeline

| Phase   | Duration | Commits | Features         |
| ------- | -------- | ------- | ---------------- |
| Phase 1 | 1 month  | 5+      | Core contracts   |
| Phase 2 | 1 month  | 8+      | Frontend v1.0    |
| Phase 3 | 1 month  | 3+      | Auditor system   |
| Phase 4 | 1 month  | 5+      | IPFS integration |

---

## 🛠️ Technical Stack

### Smart Contracts

| Component | Technology   | Version             |
| --------- | ------------ | ------------------- |
| Language  | Solidity     | ^0.8.22             |
| Framework | Foundry      | Latest              |
| Security  | OpenZeppelin | v5.x                |
| Network   | Filecoin EVM | Calibration/Mainnet |

### Frontend

| Component  | Technology      | Purpose            |
| ---------- | --------------- | ------------------ |
| Framework  | Quasar          | Vue 3 + TypeScript |
| State      | Pinia           | State management   |
| Blockchain | Filecoin AppKit | Wallet integration |
| Styling    | Tailwind CSS    | UI styling         |

### Backend

| Component  | Technology    | Purpose              |
| ---------- | ------------- | -------------------- |
| Framework  | NestJS        | API server           |
| Language   | TypeScript    | Type safety          |
| Blockchain | Ethers.js     | Contract interaction |
| Storage    | IPFS (Pinata) | File storage         |

---

## 🎯 Key Achievements

### Security

- ✅ Comprehensive security audit
- ✅ OpenZeppelin best practices
- ✅ Gas optimization (90-99% improvements)
- ✅ Input validation throughout
- ✅ Reentrancy protection

### Functionality

- ✅ Complete investment lifecycle
- ✅ Multi-auditor approval system
- ✅ IPFS permanent storage
- ✅ Privacy certificate management
- ✅ Efficient query functions

### User Experience

- ✅ Intuitive frontend interface
- ✅ Multi-wallet support
- ✅ Responsive design
- ✅ Internationalization
- ✅ Real-time status updates

---

## 🔮 Future Enhancements

### Planned Features

| Feature                          | Priority | Status  |
| -------------------------------- | -------- | ------- |
| Multi-signature auditor approval | High     | Planned |
| Advanced risk scoring            | Medium   | Planned |
| Automated compliance checks      | Medium   | Planned |
| Enhanced analytics               | Low      | Planned |
| Mobile application               | Low      | Planned |
| Cross-chain compatibility        | Low      | Future  |

---

## 📚 Documentation

- [README.md](./README.md) - Main documentation
- [README_CN.md](./README_CN.md) - 中文文档
- [DEVELOPMENT_TIMELINE_CN.md](./DEVELOPMENT_TIMELINE_CN.md) - 中文时间线

---

## 🔗 Related Repositories

- [FilNoteFEVMFront](https://github.com/filnote/FilNoteFEVMFront) - Frontend application
- [FilNoteFEVMAPI](https://github.com/filnote/FilNoteFEVMAPI) - Backend API service

---

<div align="center">

**Document Version**: 1.0  
**Last Updated**: January 2026  
**Project Status**: Active Development

[⬆ Back to Top](#-filnote-development-timeline)

</div>
