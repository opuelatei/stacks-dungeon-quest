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