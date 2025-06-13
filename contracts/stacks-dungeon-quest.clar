;; Title: Stacks Dungeon Quest - Adventure Gaming Protocol
;; Summary: A decentralized dungeon crawler game with tokenized rewards on Stacks
;; Description: Players embark on dungeon adventures by paying entry fees in approved tokens
;;              and earn rewards upon successful completion. Features cooldown mechanics,
;;              comprehensive player statistics, and administrative controls for sustainable
;;              gameplay economics. Built for Bitcoin security with Stacks scalability.


;; TRAIT DEFINITIONS

(define-trait token-trait 
    (
        (get-balance (principal) (response uint uint))
        (transfer (principal principal uint) (response bool uint))
    )
)

;; ERROR CONSTANTS

(define-constant ERR-INSUFFICIENT-BALANCE (err u1))
(define-constant ERR-UNAUTHORIZED (err u2))
(define-constant ERR-INVALID-TOKEN (err u3))
(define-constant ERR-NOT-CONTRACT-OWNER (err u4))
(define-constant ERR-INVALID-PRINCIPAL (err u5))
(define-constant ERR-PENDING-OWNER-ONLY (err u6))
(define-constant ERR-DUNGEON-COOLDOWN (err u7))
(define-constant ERR-DUNGEON-NOT-ENTERED (err u8))
(define-constant ERR-ZERO-AMOUNT (err u9))
(define-constant ERR-GAME-INACTIVE (err u10))
(define-constant ERR-MAX-DUNGEONS-REACHED (err u11))

;; GAME CONFIGURATION CONSTANTS

(define-constant ENTRY-COST u100)                    ;; Token cost to enter dungeon
(define-constant REWARD-AMOUNT u250)                 ;; Base reward for dungeon completion
(define-constant DUNGEON-COOLDOWN-BLOCKS u144)       ;; ~24 hours at 10min/block
(define-constant MAX-DUNGEONS-PER-PLAYER u1000)      ;; Lifetime dungeon limit per player
(define-constant BONUS-THRESHOLD u10)                ;; Dungeons needed for bonus rewards
(define-constant BONUS-MULTIPLIER u125)              ;; 25% bonus (125/100)

;; STATE VARIABLES

;; Contract ownership management
(define-data-var contract-owner principal tx-sender)
(define-data-var pending-owner (optional principal) none)

;; Game configuration
(define-data-var allowed-token principal 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.my-token)
(define-data-var game-active bool true)
(define-data-var total-dungeons-created uint u0)
(define-data-var contract-treasury uint u0)

;; Player tracking with enhanced statistics
(define-map player-dungeon-stats 
    { player: principal }
    {
        last-dungeon-block: uint,
        last-entry-block: uint,
        total-dungeons-completed: uint,
        total-rewards-earned: uint,
        is-in-dungeon: bool,
        consecutive-completions: uint,
        highest-streak: uint
    }
)

;; Global game statistics
(define-map game-stats
    { stat-type: (string-ascii 20) }
    { value: uint }
)

;; Leaderboard tracking
(define-map leaderboard-entries
    { rank: uint }
    { player: principal, score: uint }
)

;; PRIVATE HELPER FUNCTIONS

(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner))
)

(define-private (is-valid-token (token <token-trait>))
    (is-eq (contract-of token) (var-get allowed-token))
)

(define-private (is-valid-principal (address principal))
    (and 
        (not (is-eq address (var-get contract-owner)))
        (not (is-eq address tx-sender))
        (not (is-eq address (as-contract tx-sender)))
    )
)

(define-private (get-current-block)
    stacks-block-height
)

(define-private (max-uint (a uint) (b uint))
    (if (>= a b) a b)
)

(define-private (update-global-stats (stat-key (string-ascii 20)) (increment uint))
    (let
        (
            (current-value (default-to u0 
                (get value (map-get? game-stats { stat-type: stat-key }))
            ))
        )
        (map-set game-stats 
            { stat-type: stat-key }
            { value: (+ current-value increment) }
        )
    )
)

(define-private (calculate-reward (player principal))
    (let
        (
            (player-stats (default-to 
                {
                    last-dungeon-block: u0,
                    last-entry-block: u0,
                    total-dungeons-completed: u0, 
                    total-rewards-earned: u0,
                    is-in-dungeon: false,
                    consecutive-completions: u0,
                    highest-streak: u0
                } 
                (map-get? player-dungeon-stats { player: player })
            ))
            (base-reward REWARD-AMOUNT)
            (completion-count (get total-dungeons-completed player-stats))
        )
        (if (>= completion-count BONUS-THRESHOLD)
            (/ (* base-reward BONUS-MULTIPLIER) u100)
            base-reward
        )
    )
)

;; PUBLIC GAME FUNCTIONS

;; Enter the dungeon with comprehensive validation and fee collection
(define-public (enter-dungeon (token <token-trait>) (player principal))
    (let 
        (
            (player-balance (unwrap! (contract-call? token get-balance player) ERR-INSUFFICIENT-BALANCE))
            (current-block (get-current-block))
            (player-stats (default-to 
                {
                    last-dungeon-block: u0,
                    last-entry-block: u0,
                    total-dungeons-completed: u0, 
                    total-rewards-earned: u0,
                    is-in-dungeon: false,
                    consecutive-completions: u0,
                    highest-streak: u0
                } 
                (map-get? player-dungeon-stats { player: player })
            ))
        )
        ;; Comprehensive validation checks
        (asserts! (var-get game-active) ERR-GAME-INACTIVE)
        (asserts! (is-eq tx-sender player) ERR-UNAUTHORIZED)
        (asserts! (is-valid-token token) ERR-INVALID-TOKEN)
        (asserts! (>= player-balance ENTRY-COST) ERR-INSUFFICIENT-BALANCE)
        (asserts! (not (get is-in-dungeon player-stats)) ERR-UNAUTHORIZED)
        (asserts! (< (get total-dungeons-completed player-stats) MAX-DUNGEONS-PER-PLAYER) ERR-MAX-DUNGEONS-REACHED)
        
        ;; Check cooldown period
        (asserts! 
            (>= current-block 
                (+ (get last-entry-block player-stats) DUNGEON-COOLDOWN-BLOCKS)
            ) 
            ERR-DUNGEON-COOLDOWN
        )

        ;; Collect entry fee from player
        (try! (contract-call? token transfer player (as-contract tx-sender) ENTRY-COST))

        ;; Update contract treasury
        (var-set contract-treasury (+ (var-get contract-treasury) ENTRY-COST))

        ;; Update player stats - mark as entered dungeon
        (map-set player-dungeon-stats 
            { player: player }
            {
                last-dungeon-block: (get last-dungeon-block player-stats),
                last-entry-block: current-block,
                total-dungeons-completed: (get total-dungeons-completed player-stats),
                total-rewards-earned: (get total-rewards-earned player-stats),
                is-in-dungeon: true,
                consecutive-completions: (get consecutive-completions player-stats),
                highest-streak: (get highest-streak player-stats)
            }
        )

        ;; Update global statistics
        (update-global-stats "total-entries" u1)
        (update-global-stats "fees-collected" ENTRY-COST)
        
        (ok true)
    )
)

;; Complete dungeon challenge and claim reward with bonus calculations
(define-public (complete-dungeon (token <token-trait>) (player principal))
    (let
        (
            (current-block (get-current-block))
            (player-stats (unwrap! 
                (map-get? player-dungeon-stats { player: player })
                ERR-DUNGEON-NOT-ENTERED
            ))
            (reward-amount (calculate-reward player))
            (new-consecutive (+ (get consecutive-completions player-stats) u1))
            (new-highest-streak (max-uint (get highest-streak player-stats) new-consecutive))
        )
        ;; Validation checks
        (asserts! (var-get game-active) ERR-GAME-INACTIVE)
        (asserts! (is-eq tx-sender player) ERR-UNAUTHORIZED)
        (asserts! (is-valid-token token) ERR-INVALID-TOKEN)
        (asserts! (get is-in-dungeon player-stats) ERR-DUNGEON-NOT-ENTERED)
        (asserts! (> reward-amount u0) ERR-ZERO-AMOUNT)

        ;; Transfer reward tokens to player
        (try! (as-contract 
            (contract-call? token transfer
                tx-sender
                player
                reward-amount)
        ))

        ;; Update player dungeon statistics with enhanced tracking
        (map-set player-dungeon-stats 
            { player: player }
            {
                last-dungeon-block: current-block,
                last-entry-block: (get last-entry-block player-stats),
                total-dungeons-completed: (+ (get total-dungeons-completed player-stats) u1),
                total-rewards-earned: (+ (get total-rewards-earned player-stats) reward-amount),
                is-in-dungeon: false,
                consecutive-completions: new-consecutive,
                highest-streak: new-highest-streak
            }
        )

        ;; Update global statistics
        (update-global-stats "total-completions" u1)
        (update-global-stats "rewards-distributed" reward-amount)
        (var-set total-dungeons-created (+ (var-get total-dungeons-created) u1))

        (ok true)
    )
)

;; Forfeit current dungeon (lose entry fee but reset state)
(define-public (forfeit-dungeon (player principal))
    (let
        (
            (player-stats (unwrap! 
                (map-get? player-dungeon-stats { player: player })
                ERR-DUNGEON-NOT-ENTERED
            ))
        )
        ;; Validation checks
        (asserts! (var-get game-active) ERR-GAME-INACTIVE)
        (asserts! (is-eq tx-sender player) ERR-UNAUTHORIZED)
        (asserts! (get is-in-dungeon player-stats) ERR-DUNGEON-NOT-ENTERED)

        ;; Reset consecutive completions and exit dungeon
        (map-set player-dungeon-stats 
            { player: player }
            {
                last-dungeon-block: (get last-dungeon-block player-stats),
                last-entry-block: (get last-entry-block player-stats),
                total-dungeons-completed: (get total-dungeons-completed player-stats),
                total-rewards-earned: (get total-rewards-earned player-stats),
                is-in-dungeon: false,
                consecutive-completions: u0,
                highest-streak: (get highest-streak player-stats)
            }
        )

        ;; Update global statistics
        (update-global-stats "total-forfeits" u1)
        
        (ok true)
    )
)

;; READ-ONLY FUNCTIONS

;; Get comprehensive player statistics
(define-read-only (get-player-stats (player principal))
    (ok (default-to 
        {
            last-dungeon-block: u0,
            last-entry-block: u0,
            total-dungeons-completed: u0, 
            total-rewards-earned: u0,
            is-in-dungeon: false,
            consecutive-completions: u0,
            highest-streak: u0
        }
        (map-get? player-dungeon-stats { player: player })
    ))
)

;; Check if player can enter dungeon with detailed status
(define-read-only (can-enter-dungeon (player principal))
    (let
        (
            (current-block (get-current-block))
            (player-stats (default-to 
                {
                    last-dungeon-block: u0,
                    last-entry-block: u0,
                    total-dungeons-completed: u0, 
                    total-rewards-earned: u0,
                    is-in-dungeon: false,
                    consecutive-completions: u0,
                    highest-streak: u0
                } 
                (map-get? player-dungeon-stats { player: player })
            ))
            (cooldown-remaining (if (> (+ (get last-entry-block player-stats) DUNGEON-COOLDOWN-BLOCKS) current-block)
                                   (- (+ (get last-entry-block player-stats) DUNGEON-COOLDOWN-BLOCKS) current-block)
                                   u0))
        )
        (ok {
            can-enter: (and
                (var-get game-active)
                (not (get is-in-dungeon player-stats))
                (< (get total-dungeons-completed player-stats) MAX-DUNGEONS-PER-PLAYER)
                (>= current-block 
                    (+ (get last-entry-block player-stats) DUNGEON-COOLDOWN-BLOCKS))
            ),
            cooldown-remaining: cooldown-remaining,
            dungeons-remaining: (- MAX-DUNGEONS-PER-PLAYER (get total-dungeons-completed player-stats))
        })
    )
)

;; Get global game statistics
(define-read-only (get-game-stats (stat-type (string-ascii 20)))
    (ok (default-to u0 
        (get value (map-get? game-stats { stat-type: stat-type }))
    ))
)

;; Get all game statistics at once
(define-read-only (get-all-game-stats)
    (ok {
        total-entries: (default-to u0 (get value (map-get? game-stats { stat-type: "total-entries" }))),
        total-completions: (default-to u0 (get value (map-get? game-stats { stat-type: "total-completions" }))),
        total-forfeits: (default-to u0 (get value (map-get? game-stats { stat-type: "total-forfeits" }))),
        rewards-distributed: (default-to u0 (get value (map-get? game-stats { stat-type: "rewards-distributed" }))),
        fees-collected: (default-to u0 (get value (map-get? game-stats { stat-type: "fees-collected" }))),
        total-dungeons-created: (var-get total-dungeons-created),
        contract-treasury: (var-get contract-treasury)
    })
)

;; Get contract configuration
(define-read-only (get-game-config)
    (ok {
        entry-cost: ENTRY-COST,
        reward-amount: REWARD-AMOUNT,
        cooldown-blocks: DUNGEON-COOLDOWN-BLOCKS,
        max-dungeons-per-player: MAX-DUNGEONS-PER-PLAYER,
        bonus-threshold: BONUS-THRESHOLD,
        bonus-multiplier: BONUS-MULTIPLIER,
        allowed-token: (var-get allowed-token),
        game-active: (var-get game-active),
        contract-owner: (var-get contract-owner)
    })
)

;; Calculate potential reward for a player
(define-read-only (get-potential-reward (player principal))
    (ok (calculate-reward player))
)

;; ADMINISTRATIVE FUNCTIONS

;; Toggle game active state
(define-public (toggle-game-state)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-CONTRACT-OWNER)
        (var-set game-active (not (var-get game-active)))
        (ok (var-get game-active))
    )
)

;; Update the allowed token for the dungeon
(define-public (set-allowed-token (new-token principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-CONTRACT-OWNER)
        (asserts! (not (is-eq new-token (var-get allowed-token))) ERR-INVALID-PRINCIPAL)
        (var-set allowed-token new-token)
        (ok true)
    )
)

;; Emergency function to reset player dungeon state
(define-public (emergency-reset-player (player principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-CONTRACT-OWNER)
        (asserts! (not (is-eq player (var-get contract-owner))) ERR-INVALID-PRINCIPAL)
        (asserts! (not (is-eq player (as-contract tx-sender))) ERR-INVALID-PRINCIPAL)
        (map-delete player-dungeon-stats { player: player })
        (ok true)
    )
)

;; Withdraw treasury funds (owner only)
(define-public (withdraw-treasury (token <token-trait>) (amount uint))
    (let
        ((treasury-balance (var-get contract-treasury)))
        (asserts! (is-contract-owner) ERR-NOT-CONTRACT-OWNER)
        (asserts! (is-valid-token token) ERR-INVALID-TOKEN)
        (asserts! (<= amount treasury-balance) ERR-INSUFFICIENT-BALANCE)
        (asserts! (> amount u0) ERR-ZERO-AMOUNT)
        
        (try! (as-contract 
            (contract-call? token transfer
                tx-sender
                (var-get contract-owner)
                amount)
        ))
        
        (var-set contract-treasury (- treasury-balance amount))
        (ok true)
    )
)

;; OWNERSHIP MANAGEMENT

;; Initiate secure two-step ownership transfer
(define-public (initiate-ownership-transfer (new-owner principal))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-CONTRACT-OWNER)
        (asserts! (is-valid-principal new-owner) ERR-INVALID-PRINCIPAL)
        (var-set pending-owner (some new-owner))
        (ok true)
    )
)

;; Accept pending ownership transfer
(define-public (accept-ownership)
    (let 
        ((pending (unwrap! (var-get pending-owner) ERR-PENDING-OWNER-ONLY)))
        (asserts! (is-eq tx-sender pending) ERR-UNAUTHORIZED)
        (var-set contract-owner pending)
        (var-set pending-owner none)
        (ok true)
    )
)

;; Cancel pending ownership transfer
(define-public (cancel-ownership-transfer)
    (begin
        (asserts! (is-contract-owner) ERR-NOT-CONTRACT-OWNER)
        (var-set pending-owner none)
        (ok true)
    )
)

;; Get current and pending owner information
(define-read-only (get-ownership-info)
    (ok {
        current-owner: (var-get contract-owner),
        pending-owner: (var-get pending-owner)
    })
)