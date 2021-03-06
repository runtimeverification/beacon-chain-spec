module CONSTANTS
  imports DOMAINS

  // (Non-configurable) constants
  //====================================================
  syntax Version ::= "GENESIS_FORK_VERSION"
  rule GENESIS_FORK_VERSION => "\x00\x00\x00\x01"             [macro]
  syntax Int ::= "FAR_FUTURE_EPOCH"
  rule FAR_FUTURE_EPOCH => 2 ^Int 64 -Int 1                   [macro]
  syntax Int ::= "BASE_REWARDS_PER_EPOCH"
  rule BASE_REWARDS_PER_EPOCH => 4                            [macro]
  syntax Int ::= "DEPOSIT_CONTRACT_TREE_DEPTH"
  rule DEPOSIT_CONTRACT_TREE_DEPTH => 2 ^Int 5                [macro]
  syntax Int ::= "JUSTIFICATION_BITS_LENGTH"
  rule JUSTIFICATION_BITS_LENGTH => 4                         [macro]
  syntax String ::= "ENDIANNESS"
  rule ENDIANNESS => "little"                                 [macro]

  // Configuration -- Misc
  //====================================================
  syntax Int ::= "MAX_COMMITTEES_PER_SLOT"
  rule MAX_COMMITTEES_PER_SLOT => 4                           [macro]
  syntax Int ::= "TARGET_COMMITTEE_SIZE"
  rule TARGET_COMMITTEE_SIZE => 4                             [macro]
  syntax Int ::= "MAX_VALIDATORS_PER_COMMITTEE"
  rule MAX_VALIDATORS_PER_COMMITTEE => 2048                   [macro]
  syntax Int ::= "MIN_PER_EPOCH_CHURN_LIMIT"
  rule MIN_PER_EPOCH_CHURN_LIMIT => 4                         [macro]
  syntax Int ::= "CHURN_LIMIT_QUOTIENT"
  rule CHURN_LIMIT_QUOTIENT => 65536                          [macro]
  syntax Int ::= "SHUFFLE_ROUND_COUNT"
  rule SHUFFLE_ROUND_COUNT => 10                              [macro]
  syntax Int ::= "MIN_GENESIS_ACTIVE_VALIDATOR_COUNT"
  rule MIN_GENESIS_ACTIVE_VALIDATOR_COUNT => 64               [macro]
  syntax Int ::= "MIN_GENESIS_TIME"
  rule MIN_GENESIS_TIME => 1578009600                         [macro]

  // Configuration -- fork choice
  //====================================================
  syntax Int ::= "SAFE_SLOTS_TO_UPDATE_JUSTIFIED"
  rule SAFE_SLOTS_TO_UPDATE_JUSTIFIED => 2                    [macro] 

  // Configuration -- Gwei values
  //====================================================
  syntax Int ::= "MIN_DEPOSIT_AMOUNT"
  rule MIN_DEPOSIT_AMOUNT => 1000000000                       [macro]
  syntax Int ::= "MAX_EFFECTIVE_BALANCE"
  rule MAX_EFFECTIVE_BALANCE => 32000000000                   [macro]
  syntax Int ::= "EJECTION_BALANCE"
  rule EJECTION_BALANCE => 16000000000                        [macro]
  syntax Int ::= "EFFECTIVE_BALANCE_INCREMENT"
  rule EFFECTIVE_BALANCE_INCREMENT => 1000000000              [macro]

  // Configuration -- Initial values
  //====================================================
  syntax Int ::= "GENESIS_SLOT"
  rule GENESIS_SLOT => 0                                      [macro]
  syntax Int ::= "GENESIS_EPOCH"
  rule GENESIS_EPOCH => 0                                     [macro]
  syntax Bytes ::= "BLS_WITHDRAWAL_PREFIX"
  rule BLS_WITHDRAWAL_PREFIX => "\x00"                        [macro]

  // Configuration -- Time parameters
  //====================================================
  syntax Int ::= "MIN_GENESIS_DELAY"
  rule MIN_GENESIS_DELAY => 300                               [macro]
  syntax Int ::= "SECONDS_PER_SLOT"
  rule SECONDS_PER_SLOT => 6                                  [macro]
  syntax Int ::= "MIN_ATTESTATION_INCLUSION_DELAY"
  rule MIN_ATTESTATION_INCLUSION_DELAY => 1                   [macro]
  syntax Int ::= "SLOTS_PER_EPOCH"
  rule SLOTS_PER_EPOCH => 8                                   [macro]
  syntax Int ::= "MAX_SLOTS_PER_EPOCH"
  rule MAX_SLOTS_PER_EPOCH => 8                               [macro]
  syntax Int ::= "MIN_SEED_LOOKAHEAD"
  rule MIN_SEED_LOOKAHEAD => 1                                [macro]
  syntax Int ::= "MAX_SEED_LOOKAHEAD"
  rule MAX_SEED_LOOKAHEAD => 4                                [macro]
  syntax Int ::= "SLOTS_PER_ETH1_VOTING_PERIOD"
  rule SLOTS_PER_ETH1_VOTING_PERIOD => 16                     [macro]
  syntax Int ::= "SLOTS_PER_HISTORICAL_ROOT"
  rule SLOTS_PER_HISTORICAL_ROOT => 64                        [macro]
  syntax Int ::= "MIN_VALIDATOR_WITHDRAWABILITY_DELAY"
  rule MIN_VALIDATOR_WITHDRAWABILITY_DELAY => 256             [macro]
  syntax Int ::= "PERSISTENT_COMMITTEE_PERIOD"
  rule PERSISTENT_COMMITTEE_PERIOD => 2048                    [macro]
  syntax Int ::= "MAX_EPOCHS_PER_CROSSLINK"
  rule MAX_EPOCHS_PER_CROSSLINK => 4                          [macro]
  syntax Int ::= "MIN_EPOCHS_TO_INACTIVITY_PENALTY"
  rule MIN_EPOCHS_TO_INACTIVITY_PENALTY => 4                  [macro]
  syntax Int ::= "EARLY_DERIVED_SECRET_PENALTY_MAX_FUTURE_EPOCHS"
  rule EARLY_DERIVED_SECRET_PENALTY_MAX_FUTURE_EPOCHS => 4096 [macro]
  syntax Int ::= "EPOCHS_PER_CUSTODY_PERIOD"
  rule EPOCHS_PER_CUSTODY_PERIOD => 4                         [macro]
  syntax Int ::= "CUSTODY_PERIOD_TO_RANDAO_PADDING"
  rule CUSTODY_PERIOD_TO_RANDAO_PADDING => 4                  [macro]

  // Configuration -- State list lengths
  //====================================================
  syntax Int ::= "EPOCHS_PER_HISTORICAL_VECTOR"
  rule EPOCHS_PER_HISTORICAL_VECTOR => 64                     [macro]
  syntax Int ::= "EPOCHS_PER_SLASHINGS_VECTOR"
  rule EPOCHS_PER_SLASHINGS_VECTOR => 64                      [macro]
  syntax Int ::= "HISTORICAL_ROOTS_LIMIT"
  rule HISTORICAL_ROOTS_LIMIT => 16777216                     [macro]
  syntax Int ::= "VALIDATOR_REGISTRY_LIMIT"
  rule VALIDATOR_REGISTRY_LIMIT => 1099511627776              [macro]

  // Configuration -- Rewards and penalties
  //====================================================
  syntax Int ::= "BASE_REWARD_FACTOR"
  rule BASE_REWARD_FACTOR => 64                               [macro]
  syntax Int ::= "WHISTLEBLOWER_REWARD_QUOTIENT"
  rule WHISTLEBLOWER_REWARD_QUOTIENT => 512                   [macro]
  syntax Int ::= "PROPOSER_REWARD_QUOTIENT"
  rule PROPOSER_REWARD_QUOTIENT => 8                          [macro]
  syntax Int ::= "INACTIVITY_PENALTY_QUOTIENT"
  rule INACTIVITY_PENALTY_QUOTIENT => 33554432                [macro]
  syntax Int ::= "MIN_SLASHING_PENALTY_QUOTIENT"
  rule MIN_SLASHING_PENALTY_QUOTIENT => 32                    [macro]

  // Configuration -- Max operations per block
  //====================================================
  syntax Int ::= "MAX_PROPOSER_SLASHINGS"
  rule MAX_PROPOSER_SLASHINGS => 16                           [macro]
  syntax Int ::= "MAX_ATTESTER_SLASHINGS"
  rule MAX_ATTESTER_SLASHINGS => 1                            [macro]
  syntax Int ::= "MAX_ATTESTATIONS"
  rule MAX_ATTESTATIONS => 128                                [macro]
  syntax Int ::= "MAX_DEPOSITS"
  rule MAX_DEPOSITS => 16                                     [macro]
  syntax Int ::= "MAX_VOLUNTARY_EXITS"
  rule MAX_VOLUNTARY_EXITS => 16                              [macro]
  // syntax Int ::= "MAX_TRANSFERS"
  // rule MAX_TRANSFERS => 0                                     [macro]

  // Configuration -- domain types
  //====================================================
  syntax DomainType ::= "DOMAIN_BEACON_PROPOSER"
  rule DOMAIN_BEACON_PROPOSER => "\x00\x00\x00\x00"           [macro]
  syntax DomainType ::= "DOMAIN_BEACON_ATTESTER"
  rule DOMAIN_BEACON_ATTESTER => "\x01\x00\x00\x00"           [macro]
  syntax DomainType ::= "DOMAIN_RANDAO"
  rule DOMAIN_RANDAO => "\x02\x00\x00\x00"                    [macro]
  syntax DomainType ::= "DOMAIN_DEPOSIT"
  rule DOMAIN_DEPOSIT => "\x03\x00\x00\x00"                   [macro]
  syntax DomainType ::= "DOMAIN_VOLUNTARY_EXIT"
  rule DOMAIN_VOLUNTARY_EXIT => "\x04\x00\x00\x00"            [macro]

  // Configuration --  Validator
  //====================================================
  syntax Int ::= "ETH1_FOLLOW_DISTANCE"
  rule ETH1_FOLLOW_DISTANCE => 16                             [macro]
  syntax Int ::= "TARGET_AGGREGATORS_PER_COMMITTEE"
  rule TARGET_AGGREGATORS_PER_COMMITTEE => 16                 [macro]
  syntax Int ::= "RANDOM_SUBNETS_PER_VALIDATOR"
  rule RANDOM_SUBNETS_PER_VALIDATOR => 16                     [macro]
  syntax Int ::= "EPOCHS_PER_RANDOM_SUBNET_SUBSCRIPTION"
  rule EPOCHS_PER_RANDOM_SUBNET_SUBSCRIPTION => 256           [macro]
  syntax Int ::= "SECONDS_PER_ETH1_BLOCK"
  rule SECONDS_PER_ETH1_BLOCK => 14                           [macro]

  // for bounds checking
  syntax Int ::= "TOTAL_ETHER_SUPPLY"
  rule TOTAL_ETHER_SUPPLY => 10 ^Int 6 *Int 10 ^Int 9         [macro]


//TODO: Some phase 1 stuff here
endmodule
