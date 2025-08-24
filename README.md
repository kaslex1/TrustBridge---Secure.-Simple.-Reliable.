# 🌉 TrustBridge - Secure. Simple. Reliable.

A decentralized escrow service built on Stacks blockchain that enables safe peer-to-peer transactions without requiring trust between parties.

## 📋 Overview

TrustBridge acts as a neutral intermediary for P2P transactions, holding funds in escrow until both parties fulfill their obligations. Experience secure trading with automated protection and dispute resolution.

## ✨ Key Features

### 🔐 Trustless Escrow
- Secure fund holding during transactions
- Buyer protection with release controls
- Automatic expiration for dispute resolution
- 0.5% platform fee for service

### ⏰ Time-Based Protection
- Customizable escrow duration (up to 5 days)
- Automatic fund return on expiration
- Buyer can claim expired escrows
- Clear transaction timelines

### 📊 Transaction Tracking
- Complete escrow history per user
- Reputation building through completed trades
- Transaction volume tracking
- Status monitoring (active, completed, cancelled, expired)

### 💫 Simple Process
- Create escrow with seller details
- Seller delivers goods/services
- Buyer releases funds upon satisfaction
- Automatic fee handling and statistics

## 🏗️ Architecture

### Core Components
```clarity
escrows      -> Individual escrow transactions
user-history -> User trading history and reputation
```

### Simple Flow
1. **Create**: Buyer creates escrow with STX
2. **Deliver**: Seller provides goods/services
3. **Release**: Buyer releases funds to seller
4. **Complete**: Transaction recorded with reputation boost

## 🚀 Getting Started

### For Buyers

1. **Create Escrow**: Lock funds for a transaction
   ```clarity
   (create-escrow seller amount description duration)
   ```

2. **Verify Delivery**: Confirm goods/services received
3. **Release Funds**: Complete transaction
   ```clarity
   (release-escrow escrow-id)
   ```

### For Sellers

1. **Wait for Escrow**: Buyer creates escrow naming you as seller
2. **Deliver Product**: Provide agreed goods/services
3. **Get Paid**: Receive funds when buyer releases escrow

## 📈 Example Scenarios

### Successful Trade
```
1. Alice creates escrow: 50 STX for Bob (digital art delivery)
2. Bob delivers artwork to Alice
3. Alice releases escrow: Bob gets 49.75 STX (0.25 STX fee)
4. Both gain +1 reputation score
```

### Dispute Resolution
```
1. Alice creates escrow: 100 STX for Charlie (5-day duration)
2. Charlie fails to deliver promised service
3. Escrow expires after 5 days
4. Alice claims expired escrow, gets 100 STX back
```

### Mutual Cancellation
```
1. Dave creates escrow: 25 STX for Eve
2. Both parties agree to cancel transaction
3. Either party calls cancel-escrow()
4. Dave gets full 25 STX refund (no fees)
```

## ⚙️ Configuration

### Escrow Parameters
- **Platform Fee**: 0.5% of transaction amount
- **Maximum Duration**: 5 days (720 blocks)
- **Minimum Amount**: Any positive STX amount
- **Participants**: Buyer and named seller only

### Status Types
- **Active**: Escrow created, awaiting release
- **Completed**: Funds successfully released to seller
- **Cancelled**: Escrow cancelled by either party
- **Expired**: Duration passed, funds available to buyer

## 🔒 Security Features

### Fund Protection
- Funds locked in smart contract escrow
- Only buyer can release to seller
- Automatic refund on expiration
- No third-party access to funds

### Access Control
- Participants-only transaction management
- Buyer controls fund release
- Either party can cancel before release

### Error Handling
```clarity
ERR-NOT-AUTHORIZED (u50)     -> Insufficient permissions
ERR-ESCROW-NOT-FOUND (u51)   -> Invalid escrow ID
ERR-ALREADY-RELEASED (u52)   -> Escrow already completed/cancelled
ERR-INVALID-AMOUNT (u53)     -> Invalid amount or duration
ERR-ESCROW-ACTIVE (u54)      -> Cannot claim non-expired escrow
ERR-NOT-PARTICIPANT (u55)    -> User not buyer or seller
```

## 📊 Analytics

### Platform Metrics
- Total escrows created
- Platform fees collected
- Platform activity status

### User Statistics
- Escrows created and completed
- Total transaction volume
- Reputation score (successful completions)
- Trading history

### Escrow Details
- Transaction participants and amounts
- Creation and expiration timestamps
- Current status and completion state
- Fee calculations and distributions

## 🛠️ Development

### Prerequisites
- Clarinet CLI installed
- STX tokens for transactions
- Stacks blockchain access

### Local Testing
```bash
# Validate contract
clarinet check

# Run test suite  
clarinet test

# Deploy to testnet
clarinet deploy --testnet
```

### Integration Examples
```clarity
;; Create escrow transaction
(contract-call? .trustbridge create-escrow
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  u10000000
  "Digital artwork commission"
  u144)

;; Release funds to seller
(contract-call? .trustbridge release-escrow u1)

;; Check transaction status
(contract-call? .trustbridge get-escrow-status u1)

;; View user trading history
(contract-call? .trustbridge get-user-history tx-sender)
```

## 🎯 Use Cases

### Digital Commerce
- Freelance service payments
- Digital asset purchases
- Online marketplace transactions
- Remote work compensation

### P2P Trading
- NFT and collectible sales
- Cryptocurrency OTC trades
- Service exchange agreements
- Community marketplace transactions

### Business Applications
- Vendor payment processing
- Customer deposit handling
- Contract milestone payments
- Supply chain settlements

## 📋 Quick Reference

### Core Functions
```clarity
;; Transaction Management
create-escrow(seller, amount, description, duration) -> escrow-id
release-escrow(escrow-id) -> success
cancel-escrow(escrow-id) -> success
claim-expired-escrow(escrow-id) -> success

;; Information Queries
get-escrow(escrow-id) -> escrow-data
get-escrow-status(escrow-id) -> status
get-user-history(user) -> statistics
```

## 🚦 Deployment Guide

1. Deploy contract to target network
2. Configure platform parameters
3. Test with small transactions
4. Launch with community education
5. Monitor usage and collect feedback

## 🤝 Contributing

TrustBridge welcomes community contributions:
- Security audits and improvements
- Feature enhancements
- Documentation updates
- Testing and bug reports

---

**⚠️ Disclaimer**: TrustBridge is escrow software for P2P transactions. Understand the risks and ensure proper due diligence before engaging in transactions.
