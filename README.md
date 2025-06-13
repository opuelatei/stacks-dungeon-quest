# Stacks Dungeon Quest 🏰⚔️

A decentralized dungeon crawler adventure game built on the Stacks blockchain, combining the security of Bitcoin with the scalability of smart contracts. Players embark on dungeon adventures by paying entry fees in approved tokens and earn tokenized rewards upon successful completion.

## 🎮 System Overview

Stacks Dungeon Quest implements a sustainable gaming economy where players:

- Pay entry fees to enter dungeons
- Complete challenges to earn rewards
- Build consecutive completion streaks for bonus rewards
- Compete on leaderboards with comprehensive statistics tracking

The game features cooldown mechanics to prevent spam, lifetime dungeon limits per player, and administrative controls to maintain balanced gameplay economics.

## 🏗️ Contract Architecture

### Core Components

```
┌─────────────────────────────────────────────────────┐
│                 STACKS DUNGEON QUEST                │
├─────────────────────────────────────────────────────┤
│  Game Logic Layer                                   │
│  ├─ Entry System (Fee Collection)                   │
│  ├─ Completion System (Reward Distribution)         │
│  ├─ Forfeit System (State Management)               │
│  └─ Bonus Calculation Engine                        │
├─────────────────────────────────────────────────────┤
│  State Management Layer                             │
│  ├─ Player Statistics Tracking                      │
│  ├─ Global Game Statistics                          │
│  ├─ Cooldown Management                             │
│  └─ Treasury Management                             │
├─────────────────────────────────────────────────────┤
│  Security & Administration Layer                    │
│  ├─ Ownership Management (2-Step Transfer)          │
│  ├─ Emergency Controls                              │
│  ├─ Token Validation                                │
│  └─ Access Control                                  │
├─────────────────────────────────────────────────────┤
│  Token Integration Layer                            │
│  ├─ SIP-010 Token Trait Implementation             │
│  ├─ Balance Verification                            │
│  └─ Transfer Operations                             │
└─────────────────────────────────────────────────────┘
```

### Key Data Structures

**Player Statistics (`player-dungeon-stats`)**

- Dungeon completion tracking
- Reward earnings history
- Consecutive completion streaks
- Cooldown state management
- Current dungeon status

**Global Statistics (`game-stats`)**

- Total entries and completions
- Rewards distributed
- Fees collected
- Forfeit tracking

**Game Configuration**

- Entry costs and reward amounts
- Cooldown periods and limits
- Bonus thresholds and multipliers
- Allowed token contracts

## 🔄 Data Flow

### Dungeon Entry Process

```
Player Request → Balance Check → Cooldown Validation → Fee Collection → State Update
     ↓              ↓               ↓                    ↓               ↓
Tx Sender      Token Balance   Last Entry Block    Transfer Tokens   Mark In-Dungeon
Validation     ≥ Entry Cost    + Cooldown Period   to Contract       Update Stats
```

### Dungeon Completion Process

```
Completion Request → Validation → Reward Calculation → Token Transfer → Statistics Update
        ↓               ↓              ↓                   ↓               ↓
    In-Dungeon      Game Active    Base + Bonus        Contract →      Streak Tracking
    Status Check    Token Valid    Calculation         Player          Global Stats
```

### Administrative Operations

```
Owner Actions → Access Control → State Modification → Event Logging
     ↓              ↓                  ↓                  ↓
Game Toggle     Owner Validation   Update Variables   Track Changes
Token Update    Principal Check    Reset Player       Treasury Ops
Emergency Reset Two-Step Transfer  Ownership Transfer
```

## 🎯 Key Features

### Player Experience

- **Entry System**: Pay tokens to enter dungeons with balance and cooldown validation
- **Completion Rewards**: Earn base rewards plus streak bonuses for consecutive completions
- **Forfeit Option**: Exit dungeons early (lose entry fee but reset state)
- **Statistics Tracking**: Comprehensive player progress and achievement tracking

### Economic Mechanics

- **Entry Cost**: 100 tokens per dungeon entry
- **Base Reward**: 250 tokens for successful completion
- **Bonus System**: 25% bonus rewards after 10+ completions
- **Cooldown Period**: 144 blocks (~24 hours) between dungeon entries
- **Lifetime Limit**: 1,000 dungeons per player maximum

### Administrative Controls

- **Game State Management**: Toggle active/inactive status
- **Token Configuration**: Update approved payment tokens
- **Emergency Functions**: Reset player states if needed
- **Treasury Management**: Withdraw collected fees
- **Secure Ownership**: Two-step ownership transfer process

## 🔐 Security Features

### Access Control

- Owner-only administrative functions
- Player-specific transaction validation
- Contract-level token verification
- Principal validation for sensitive operations

### State Protection

- Comprehensive input validation
- Balance verification before transfers
- Cooldown enforcement
- Maximum dungeon limits
- Anti-spam protections

### Economic Security

- Separate treasury tracking
- Controlled reward distribution
- Fee collection validation
- Emergency reset capabilities

## 📊 Statistics & Analytics

### Player Metrics

- Total dungeons completed
- Total rewards earned
- Current and highest consecutive streaks
- Last activity timestamps
- Current dungeon status

### Global Metrics

- Total entries and completions
- Rewards distributed across all players
- Fees collected in treasury
- Forfeit rates and patterns
- Active player engagement

## 🚀 Usage

### For Players

```clarity
;; Enter a dungeon
(contract-call? .dungeon-quest enter-dungeon .my-token tx-sender)

;; Complete current dungeon
(contract-call? .dungeon-quest complete-dungeon .my-token tx-sender)

;; Check eligibility
(contract-call? .dungeon-quest can-enter-dungeon tx-sender)

;; View statistics
(contract-call? .dungeon-quest get-player-stats tx-sender)
```

### For Administrators

```clarity
;; Toggle game state
(contract-call? .dungeon-quest toggle-game-state)

;; Update allowed token
(contract-call? .dungeon-quest set-allowed-token 'SP123...NEW-TOKEN)

;; Withdraw treasury funds
(contract-call? .dungeon-quest withdraw-treasury .my-token u1000)
```

## 🛠️ Technical Specifications

- **Blockchain**: Stacks (Bitcoin Layer 2)
- **Language**: Clarity Smart Contract Language
- **Token Standard**: SIP-010 Fungible Token Trait
- **Block Time**: ~10 minutes (Bitcoin-based)
- **Cooldown**: 144 blocks (~24 hours)

## 📈 Tokenomics

**Revenue Model**: Entry fees collected in contract treasury
**Reward Distribution**: Fixed base rewards with performance bonuses
**Economic Sustainability**: Configurable parameters for long-term balance
**Treasury Management**: Owner-controlled fund withdrawal and allocation

## 🔮 Future Enhancements

- Multi-tier dungeon difficulty levels
- NFT-based achievement systems
- Seasonal events and special rewards
- Cross-chain token integration
- Advanced leaderboard features
- Guild and team-based gameplay
