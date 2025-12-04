# FilNote - Decentralized Investment Note Protocol on Filecoin EVM

[中文文档](./README_CN.md)

## Overview

FilNote is a decentralized investment note protocol built on Filecoin EVM (FEVM). It enables users to create, invest in, and manage investment notes with automated interest calculations and protocol contract management. The system implements a secure, transparent, and trustless mechanism for peer-to-peer lending and investment.

## Features

- **Note Creation**: Create investment notes with customizable target amounts, interest rates, and borrowing periods
- **Auditor System**: Multi-auditor approval system for note verification before investment
- **Privacy Certificate Support**: Support for encrypted privacy certificate storage and public information preview
- **Protocol Contracts**: Automated protocol contract deployment for each investment
- **Platform Fees**: Configurable platform fee system with recipient management
- **Lifecycle Management**: Complete note lifecycle from creation to completion/default
- **Security**: Built with OpenZeppelin's security libraries (Ownable, ReentrancyGuard)
- **Pagination Support**: Efficient data retrieval with pagination for large datasets

## Architecture

### Core Contracts

1. **FilNoteContract** (`src/FilNote.sol`)

   - Main contract managing investment notes
   - Handles note creation, investment, and status management
   - Manages auditor system and platform fees

2. **ProtocolsContract** (`src/Protocols.sol`)

   - Protocol contract deployed for each active investment
   - Manages funding pool and withdrawals
   - Handles interest calculations and maturity checks

3. **Types** (`src/utils/Types.sol`)
   - Data structures and error definitions
   - Note status enumeration
   - Protocol information structures

### Note Lifecycle

```
INIT → PENDING → ACTIVE → COMPLETED/DEFAULTED
  ↓        ↓
CLOSED   STOP
```

1. **INIT**: Note created by creator, awaiting auditor approval
2. **PENDING**: Approved by auditor with contract hash (and optionally encrypted privacy certificate hash and public preview hash), open for investment
3. **ACTIVE**: Investment received, protocol contract deployed
4. **COMPLETED**: Successfully repaid with interest
5. **DEFAULTED**: Failed to meet repayment obligations
6. **CLOSED**: Closed by creator or owner before investment
7. **STOP**: Stopped by contract owner during active state, all funds returned to investor

### Privacy Certificate Management

- **Encrypted Privacy Certificate Hash**: Full privacy certificate IPFS hash encrypted using platform wallet, stored on-chain
- **Privacy Credentials Abridged Hash**: Public preview version (jsonData) of privacy certificate, stored on IPFS as JSON, visible to all users
- **Access Control**: Full privacy certificate can only be decrypted by note creators or investors after investment

## Contract Details

### FilNoteContract

#### Key Functions

- `createNote(uint256 targetAmount, uint16 interestRateBps, uint16 borrowingDays)`: Create a new investment note
- `invest(uint64 id)`: Invest in a pending note (payable)
- `pendingNote(uint64 id, string calldata contractHash, string calldata encryptedPrivacyCertificateHash, string calldata privacyCredentialsAbridgedHash)`: Approve note for investment (auditor only)
- `closeNote(uint64 id)`: Close a note (creator or owner)
- `stopNote(uint64 id)`: Stop an active note (owner only), returns all funds to investor
- `completeNote(uint64 id)`: Mark note as completed (protocol contract only)
- `defaultNote(uint64 id)`: Mark note as defaulted (protocol contract only)

#### Query Functions

- `getNote(uint64 id)`: Get note by ID
- `getNotes(uint256 offset, uint256 limit)`: Get paginated list of notes
- `getNoteByIds(uint64[] calldata ids)`: Get multiple notes by IDs
- `getNotesByCreator(address creator, uint256 offset, uint256 limit)`: Get creator's notes
- `getNotesByInvestor(address investor, uint256 offset, uint256 limit)`: Get investor's notes
- `getTotalNotes()`: Get total number of notes

#### Admin Functions

- `addAuditor(address auditor)`: Add an auditor (owner only)
- `removeAuditor(address auditor)`: Remove an auditor (owner only)
- `setPlatformFee(uint256 platformFee)`: Set platform fee rate (owner only)
- `setPlatformFeeRecipient(address platformFeeRecipient)`: Set fee recipient (owner only)

### ProtocolsContract

#### Key Functions

- `withdrawFundingAmount()`: Creator withdraws initial funding
- `spWithdrawPoolAmount(uint256 amount)`: Creator withdraws from pool (with reserve check)
- `investorWithdrawPoolAmount()`: Investor withdraws after maturity
- `stopProtocol()`: Stop protocol and return all contract balance to investor (FilNote contract only)

#### Query Functions

- `getProtocolInfo()`: Get associated note information
- `getContractInfo()`: Get funding and pool amounts

## Deployment

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Node.js and npm/yarn
- Private key for deployment

### Build

```bash
forge build
```

### Calibration Testnet Deployment

```bash
forge create src/FilNote.sol:FilNoteContract \
  --rpc-url https://api.calibration.node.glif.io/rpc/v1 \
  --private-key <PRIVATE_KEY> \
  --broadcast \
  --verify \
  --verifier sourcify \
  -vvvv
```

**Current deployed testnet address**: [0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30](https://filecoin-testnet.blockscout.com/address/0xD88dB8719f066a88F7FA67Ce7761b428f95B7C30?tab=read_contract)

### Flatten Contract

```bash
forge flatten src/FilNote.sol -o flattened/FilNote.sol
```

## Usage

### Creating a Note

```solidity
// Create a note with:
// - Target amount: 1 FIL (1e18 wei)
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
// Approve note with IPFS contract hash and optional privacy certificate
filNoteContract.pendingNote(
    noteId,
    "QmYourIPFSHashHere",  // contractHash (required)
    "encryptedHash...",     // encryptedPrivacyCertificateHash (optional)
    "QmPreviewHash..."      // privacyCredentialsAbridgedHash (optional, public preview)
);
```

### Investing in a Note

```solidity
// Invest exact target amount
filNoteContract.invest{value: 1e18}(noteId);
```

### Withdrawing Funds (Protocol Contract)

```solidity
// Creator withdraws initial funding
protocolContract.withdrawFundingAmount();

// Creator withdraws from pool (maintains minimum reserve)
protocolContract.spWithdrawPoolAmount(amount);

// Investor withdraws after maturity
protocolContract.investorWithdrawPoolAmount();
```

## Security Features

- **Reentrancy Protection**: All state-changing functions use ReentrancyGuard
- **Access Control**: Owner-only functions for critical operations
- **Input Validation**: Comprehensive parameter validation
- **Safe Math**: Using OpenZeppelin's Math library for calculations
- **Minimum Reserve**: Protocol contracts maintain minimum reserve for investor protection
- **Auditor System**: Multi-auditor approval for note verification

## Development

### Project Structure

```
FilNoteFEVM/
├── src/
│   ├── FilNote.sol          # Main contract
│   ├── Protocols.sol        # Protocol contract
│   └── utils/
│       └── Types.sol        # Data structures
├── script/                  # Deployment scripts
├── test/                    # Test files
├── lib/                     # Dependencies
└── foundry.toml            # Foundry configuration
```

### Dependencies

- OpenZeppelin Contracts (Ownable, ReentrancyGuard, Math)
- Forge Std
- Filecoin Solidity API

### Linting

```bash
# Format code
yarn prettier

# Check formatting
yarn prettier:check

# Lint Solidity
yarn solhint

# Run all linting
yarn lint
```

### Testing

```bash
forge test
```

## Configuration

### Foundry Configuration

The project uses Foundry with the following key settings:

- Solidity version: `0.8.22`
- Optimizer: Enabled (200 runs)
- Via IR: Enabled
- Chain ID: 314159 (Calibration testnet)

See `foundry.toml` for full configuration.

## License

MIT License - see [LICENSE](./LICENSE) file for details.

## Links

- **Testnet Explorer**: [Filecoin Calibration Blockscout](https://filecoin-testnet.blockscout.com/)
- **RPC Endpoint**: https://api.calibration.node.glif.io/rpc/v1
- **Foundry Documentation**: https://book.getfoundry.sh/

## Contributing

Contributions are welcome! Please ensure all code follows the project's linting standards and includes appropriate tests.
