module BEACON-CHAIN
  imports DOMAINS
  imports BYTES-HOOKED

/*
class BeaconState(Container):
    # Misc
    slot: uint64
    genesis_time: uint64
    fork: Fork  # For versioning hard forks
    # Validator registry
    validator_registry: List[Validator]
    balances: List[uint64]
    # Randomness and committees
    latest_randao_mixes: Vector[Bytes32, LATEST_RANDAO_MIXES_LENGTH]
    latest_start_shard: uint64
    # Finality
    previous_epoch_attestations: List[PendingAttestation]
    current_epoch_attestations: List[PendingAttestation]
    previous_justified_epoch: uint64
    current_justified_epoch: uint64
    previous_justified_root: Bytes32
    current_justified_root: Bytes32
    justification_bitfield: uint64
    finalized_epoch: uint64
    finalized_root: Bytes32
    # Recent state
    current_crosslinks: Vector[Crosslink, SHARD_COUNT]
    previous_crosslinks: Vector[Crosslink, SHARD_COUNT]
    latest_block_roots: Vector[Bytes32, SLOTS_PER_HISTORICAL_ROOT]
    latest_state_roots: Vector[Bytes32, SLOTS_PER_HISTORICAL_ROOT]
    latest_active_index_roots: Vector[Bytes32, LATEST_ACTIVE_INDEX_ROOTS_LENGTH]
    latest_slashed_balances: Vector[uint64, LATEST_SLASHED_EXIT_LENGTH]
    latest_block_header: BeaconBlockHeader
    historical_roots: List[Bytes32]
    # Ethereum 1.0 chain data
    latest_eth1_data: Eth1Data
    eth1_data_votes: List[Eth1Data]
    deposit_index: uint64

class BeaconBlock(Container):
    # Header
    slot: uint64
    parent_root: Bytes32
    state_root: Bytes32
    body: BeaconBlockBody
    signature: Bytes96

class BeaconBlockBody(Container):
    randao_reveal: Bytes96
    eth1_data: Eth1Data
    graffiti: Bytes32
    proposer_slashings: List[ProposerSlashing]
    attester_slashings: List[AttesterSlashing]
    attestations: List[Attestation]
    deposits: List[Deposit]
    voluntary_exits: List[VoluntaryExit]
    transfers: List[Transfer]

class ProposerSlashing(Container):
    proposer_index: ValidatorIndex
    header_1: BeaconBlockHeader
    header_2: BeaconBlockHeader
*/
  configuration
    <beacon-chain>
      <k> $PGM:Pgm </k>
      <state>                           //Type BeaconState in python spec.
        <slot> 0 </slot>
        <genesis-time> 0 </genesis-time>
        <fork> .Fork </fork>
        <validator-registry> .Map </validator-registry> //List[Validator]
        <balances> .Map </balances> //List[Gwei]
        <latest-randao-mixes> .Bytes32List </latest-randao-mixes>
        <latest-start-shard> 0 </latest-start-shard>
        <previous-epoch-attestations> .PendingAttestationList </previous-epoch-attestations>
        <current-epoch-attestations> .PendingAttestationList </current-epoch-attestations>
        <previous-justified-epoch> 0 </previous-justified-epoch>
        <current-justified-epoch> 0 </current-justified-epoch>
        <previous-justified-root> 0 </previous-justified-root>
        <current-justified-root> 0 </current-justified-root>
        <justification-bitfield> 0:Uint64 </justification-bitfield>
        <finalized-epoch> 0 </finalized-epoch>
        <finalized-root> 0 </finalized-root>
        <current-crosslinks> .CrosslinkList </current-crosslinks>
        <previous-crosslinks> .CrosslinkList </previous-crosslinks>
        <latest-block-roots> .Bytes32List </latest-block-roots>
        <latest-state-roots> .Bytes32List </latest-state-roots>
        <latest-active-index-roots> .Bytes32List </latest-active-index-roots>
        <latest-slashed-balances> .Uint64List </latest-slashed-balances>
        <latest-block-header> .BlockHeader </latest-block-header>
        <historical-roots> .Bytes32List </historical-roots>
        <latest-eth1-data> .Eth1Data </latest-eth1-data>
        <eth1-data-votes> .Eth1DataList </eth1-data-votes>
        <deposit-index> 0 </deposit-index>
        <slashings> .Map </slashings>
      </state>
      <block>                           //Type BeaconBlock in python spec.
        <blockSlot> -1 </blockSlot>
        <parent-root> -1 </parent-root>
        <state-root> -1 </state-root>
        <body>                          //Type BeaconBlockBody in python spec.
          <randao-reveal> -1 </randao-reveal>
          <eth1-data> .Eth1Data </eth1-data>
          <graffiti> -1 </graffiti>
          <proposer-slashings>
            <proposer-slashing>
              <proposer-index> -1 </proposer-index>
              <header1> .BlockHeader </header1>
              <header2> .BlockHeader </header2>
            </proposer-slashing>
          </proposer-slashings>
          <attester-slashings> .AttesterSlashingList </attester-slashings>
          <attestations> .AttestationList </attestations>
          <deposits> .DepositList </deposits>
          <voluntary-exits> .VoluntaryExitList </voluntary-exits>
          <transfers> .TransferList </transfers>
        </body>
        <signature> -1 </signature>
      </block>
    </beacon-chain>

  syntax KItem ::= Pgm
  syntax Pgm ::= ".Pgm"
  syntax Fork ::= ".Fork"
  syntax BlockHeader ::= ".BlockHeader" | BeaconBlockHeader
  syntax Eth1Data ::= ".Eth1Data"

  syntax Bytes ::= #Bytes( Int, Int ) //DATA, LEN
  syntax Uint64 ::= Int

  syntax Uint64List ::= List{Uint64, ""}
  syntax Bytes32List ::= List{Bytes32, ""}
  syntax AttesterSlashingList ::= List{AttesterSlashing, ""}
  syntax AttestationList ::= List{Attestation, ""}
  syntax DepositList ::= List{Deposit, ""}
  syntax VoluntaryExitList ::= List{VoluntaryExit, ""}
  syntax TransferList ::= List{Transfer, ""}
  syntax CrosslinkList ::= List{Crosslink, ""}
  syntax Eth1DataList ::= List{Eth1Data, ""}
  syntax PendingAttestationList ::= List{PendingAttestation, ""}
  syntax IntList ::= List{Int, ""}

  // Python spec types
  //====================================================
  syntax Slot ::= Int
  syntax Epoch ::= Int
  syntax Shard ::= Int
  syntax ValidatorIndex ::= Int | ".ValidatorIndex"
  syntax Gwei ::= Int

  syntax Bytes4  ::= Int
  syntax Bytes32 ::= Int
  syntax Bytes48 ::= Int
  syntax Bytes96 ::= Int

  syntax Int ::= "SHARD_COUNT"
  rule SHARD_COUNT => 2 ^Int 10                               [macro]
  syntax Int ::= "TARGET_COMMITTEE_SIZE"
  rule TARGET_COMMITTEE_SIZE => 2 ^Int 7                      [macro]
  syntax Int ::= "MAX_INDICES_PER_ATTESTATION"
  rule MAX_INDICES_PER_ATTESTATION => 2 ^Int 12               [macro]
  syntax Int ::= "MIN_PER_EPOCH_CHURN_LIMIT"
  rule MIN_PER_EPOCH_CHURN_LIMIT => 2 ^Int 2                  [macro]
  syntax Int ::= "CHURN_LIMIT_QUOTIENT"
  rule CHURN_LIMIT_QUOTIENT => 2 ^Int 16                      [macro]
  syntax Int ::= "BASE_REWARDS_PER_EPOCH"
  rule BASE_REWARDS_PER_EPOCH => 5                            [macro]
  syntax Int ::= "SHUFFLE_ROUND_COUNT"
  rule SHUFFLE_ROUND_COUNT => 90                              [macro]
  syntax Int ::= "DEPOSIT_CONTRACT_TREE_DEPTH"
  rule DEPOSIT_CONTRACT_TREE_DEPTH => 2 ^Int 5                [macro]
  syntax Int ::= "MIN_DEPOSIT_AMOUNT"
  rule MIN_DEPOSIT_AMOUNT => 2 ^Int 0 *Int 10 ^Int 9          [macro]
  syntax Int ::= "MAX_EFFECTIVE_BALANCE"
  rule MAX_EFFECTIVE_BALANCE => 2 ^Int 5 *Int 10 ^Int 9       [macro]
  syntax Int ::= "EJECTION_BALANCE"
  rule EJECTION_BALANCE => 2 ^Int 4 *Int 10 ^Int 9            [macro]
  syntax Int ::= "EFFECTIVE_BALANCE_INCREMENT"
  rule EFFECTIVE_BALANCE_INCREMENT => 2 ^Int 0 *Int 10 ^Int 9 [macro]
  syntax Int ::= "GENESIS_SLOT"
  rule GENESIS_SLOT => 0                                      [macro]
  syntax Int ::= "GENESIS_EPOCH"
  rule GENESIS_EPOCH => 0                                     [macro]
  syntax Int ::= "FAR_FUTURE_EPOCH"
  rule FAR_FUTURE_EPOCH => 2 ^Int 64 -Int 1                   [macro]
  syntax Int ::= "ZERO_HASH"
  rule ZERO_HASH => 0 /*b'\x00' *Int 32*/                     [macro]
  syntax Int ::= "BLS_WITHDRAWAL_PREFIX"
  rule BLS_WITHDRAWAL_PREFIX => 0                             [macro]
  syntax Int ::= "MIN_ATTESTATION_INCLUSION_DELAY"
  rule MIN_ATTESTATION_INCLUSION_DELAY => 2 ^Int 2            [macro]
  syntax Int ::= "SLOTS_PER_EPOCH"
  rule SLOTS_PER_EPOCH => 2 ^Int 6                            [macro]
  syntax Int ::= "MIN_SEED_LOOKAHEAD"
  rule MIN_SEED_LOOKAHEAD => 2 ^Int 0                         [macro]
  syntax Int ::= "ACTIVATION_EXIT_DELAY"
  rule ACTIVATION_EXIT_DELAY => 2 ^Int 2                      [macro]
  syntax Int ::= "SLOTS_PER_ETH1_VOTING_PERIOD"
  rule SLOTS_PER_ETH1_VOTING_PERIOD => 2 ^Int 10              [macro]
  syntax Int ::= "SLOTS_PER_HISTORICAL_ROOT"
  rule SLOTS_PER_HISTORICAL_ROOT => 2 ^Int 13                 [macro]
  syntax Int ::= "MIN_VALIDATOR_WITHDRAWABILITY_DELAY"
  rule MIN_VALIDATOR_WITHDRAWABILITY_DELAY => 2 ^Int 8        [macro]
  syntax Int ::= "PERSISTENT_COMMITTEE_PERIOD"
  rule PERSISTENT_COMMITTEE_PERIOD => 2 ^Int 11               [macro]
  syntax Int ::= "MAX_EPOCHS_PER_CROSSLINK"
  rule MAX_EPOCHS_PER_CROSSLINK => 2 ^Int 6                   [macro]
  syntax Int ::= "MIN_EPOCHS_TO_INACTIVITY_PENALTY"
  rule MIN_EPOCHS_TO_INACTIVITY_PENALTY => 2 ^Int 2           [macro]
  syntax Int ::= "EPOCHS_PER_SLASHINGS_VECTOR"
  rule EPOCHS_PER_SLASHINGS_VECTOR => 2 ^Int 13               [macro]
  syntax Int ::= "LATEST_RANDAO_MIXES_LENGTH"
  rule LATEST_RANDAO_MIXES_LENGTH => 2 ^Int 13                [macro]
  syntax Int ::= "LATEST_ACTIVE_INDEX_ROOTS_LENGTH"
  rule LATEST_ACTIVE_INDEX_ROOTS_LENGTH => 2 ^Int 13          [macro]
  syntax Int ::= "LATEST_SLASHED_EXIT_LENGTH"
  rule LATEST_SLASHED_EXIT_LENGTH => 2 ^Int 13                [macro]
  syntax Int ::= "BASE_REWARD_FACTOR"
  rule BASE_REWARD_FACTOR => 2 ^Int 5                         [macro]
  syntax Int ::= "WHISTLEBLOWER_REWARD_QUOTIENT"
  rule WHISTLEBLOWER_REWARD_QUOTIENT => 2 ^Int 9              [macro]
  syntax Int ::= "PROPOSER_REWARD_QUOTIENT"
  rule PROPOSER_REWARD_QUOTIENT => 2 ^Int 3                   [macro]
  syntax Int ::= "INACTIVITY_PENALTY_QUOTIENT"
  rule INACTIVITY_PENALTY_QUOTIENT => 2 ^Int 25               [macro]
  syntax Int ::= "MIN_SLASHING_PENALTY_QUOTIENT"
  rule MIN_SLASHING_PENALTY_QUOTIENT => 2 ^Int 5              [macro]
  syntax Int ::= "MAX_PROPOSER_SLASHINGS"
  rule MAX_PROPOSER_SLASHINGS => 2 ^Int 4                     [macro]
  syntax Int ::= "MAX_ATTESTER_SLASHINGS"
  rule MAX_ATTESTER_SLASHINGS => 2 ^Int 0                     [macro]
  syntax Int ::= "MAX_ATTESTATIONS"
  rule MAX_ATTESTATIONS => 2 ^Int 7                           [macro]
  syntax Int ::= "MAX_DEPOSITS"
  rule MAX_DEPOSITS => 2 ^Int 4                               [macro]
  syntax Int ::= "MAX_VOLUNTARY_EXITS"
  rule MAX_VOLUNTARY_EXITS => 2 ^Int 4                        [macro]
  syntax Int ::= "MAX_TRANSFERS"
  rule MAX_TRANSFERS => 0                                     [macro]
  syntax Int ::= "DOMAIN_BEACON_PROPOSER"
  rule DOMAIN_BEACON_PROPOSER => 0                            [macro]
  syntax Int ::= "DOMAIN_RANDAO"
  rule DOMAIN_RANDAO => 1                                     [macro]
  syntax Int ::= "DOMAIN_ATTESTATION"
  rule DOMAIN_ATTESTATION => 2                                [macro]
  syntax Int ::= "DOMAIN_DEPOSIT"
  rule DOMAIN_DEPOSIT => 3                                    [macro]
  syntax Int ::= "DOMAIN_VOLUNTARY_EXIT"
  rule DOMAIN_VOLUNTARY_EXIT => 4                             [macro]
  syntax Int ::= "DOMAIN_TRANSFER"
  rule DOMAIN_TRANSFER => 5                                   [macro]

  /*
class Fork(Container):
    # Previous fork version
    previous_version: Bytes4
    # Current fork version
    current_version: Bytes4
    # Fork epoch number
    epoch: uint64
  */
  syntax Fork ::= #Fork( Bytes4, Bytes4, Epoch ) [klabel(#Fork), symbol]

  /*
class Crosslink(Container):
    # Shard number
    shard: uint64
    # Crosslinking data from epochs [start....end-1]
    start_epoch: uint64
    end_epoch: uint64
    # Root of the previous crosslink
    parent_root: Bytes32
    # Root of the crosslinked shard data since the previous crosslink
    data_root: Bytes32
  */
  syntax Crosslink ::= #Crosslink( Shard, Epoch, Epoch, Bytes32, Bytes32 ) [klabel(#Crosslink), symbol]

  /*
class VoluntaryExit(Container):
    # Minimum epoch for processing exit
    epoch: uint64
    # Index of the exiting validator
    validator_index: uint64
    # Validator signature
    signature: Bytes96
  */
  syntax VoluntaryExit ::= #VoluntaryExit( Epoch, ValidatorIndex, Bytes96 )

  /*
class Validator(Container):
    # BLS public key
    pubkey: Bytes48
    # Withdrawal credentials
    withdrawal_credentials: Bytes32
    # Epoch when became eligible for activation
    activation_eligibility_epoch: uint64
    # Epoch when validator activated
    activation_epoch: uint64
    # Epoch when validator exited
    exit_epoch: uint64
    # Epoch when validator is eligible to withdraw
    withdrawable_epoch: uint64
    # Was the validator slashed
    slashed: bool
    # Effective balance
    effective_balance: uint64
  */
  syntax Validator ::= #Validator( Bytes48, Bytes32, Epoch, Epoch, Epoch, Epoch, Bool, Uint64 ) [klabel(#Validator), symbol]

  /*
class IndexedAttestation(Container):
    # Validator indices
    custody_bit_0_indices: List[uint64]
    custody_bit_1_indices: List[uint64]
    # Attestation data
    data: AttestationData
    # Aggregate signature
    signature: Bytes96
  */
  syntax IndexedAttestation ::= #IndexedAttestation( Uint64List, Uint64List, AttestationData, Bytes96 )

  /*
class PendingAttestation(Container):
    # Attester aggregation bitfield
    aggregation_bitfield: bytes
    # Attestation data
    data: AttestationData
    # Inclusion delay
    inclusion_delay: uint64
    # Proposer index
    proposer_index: uint64
  */
  syntax PendingAttestation ::= #PendingAttestation( Bytes, AttestationData, Uint64, Uint64 ) [klabel(#PendingAttestation), symbol]

  /*
class Deposit(Container):
    # Branch in the deposit tree
    proof: Vector[Bytes32, DEPOSIT_CONTRACT_TREE_DEPTH]
    # Data
    data: DepositData
  */
  syntax Deposit ::= #Deposit( Bytes32List, DepositData )

  /*
class Transfer(Container):
    # Sender index
    sender: uint64
    # Recipient index
    recipient: uint64
    # Amount in Gwei
    amount: uint64
    # Fee in Gwei for block proposer
    fee: uint64
    # Inclusion slot
    slot: uint64
    # Sender withdrawal pubkey
    pubkey: Bytes48
    # Sender signature
    signature: Bytes96
  */
  syntax Transfer ::= #Transfer( Uint64, Uint64, Gwei, Gwei, Slot, Bytes48, Bytes96 )

  /*
class AttestationDataAndCustodyBit(Container):
    # Attestation data
    data: AttestationData
    # Custody bit
    custody_bit: bool
  */
  syntax AttestationDataAndCustodyBit ::= #AttestationDataAndCustodyBit( AttestationData, Bool )

  /*
class DepositData(Container):
    # BLS pubkey
    pubkey: Bytes48
    # Withdrawal credentials
    withdrawal_credentials: Bytes32
    # Amount in Gwei
    amount: uint64
    # Container self-signature
    signature: Bytes96
  */
  syntax DepositData ::= #DepositData( Bytes48, Bytes32, Gwei, Bytes96 )

  /*
class AttestationData(Container):
    # LMD GHOST vote
    beacon_block_root: Bytes32

    # FFG vote
    source_epoch: uint64
    source_root: Bytes32
    target_epoch: uint64
    target_root: Bytes32

    # Crosslink vote
    crosslink: Crosslink
  */
  syntax AttestationData ::= #AttestationData( Bytes32, Epoch, Bytes32, Epoch, Bytes32, Crosslink ) [klabel(#AttestationData), symbol]

  /*
class HistoricalBatch(Container):
    # Block roots
    block_roots: Vector[Bytes32, SLOTS_PER_HISTORICAL_ROOT]
    # State roots
    state_roots: Vector[Bytes32, SLOTS_PER_HISTORICAL_ROOT]
  */
  syntax HistoricalBatch ::= #HistoricalBatch( Bytes32List, Bytes32List )

  /*
class Attestation(Container):
    # Attester aggregation bitfield
    aggregation_bitfield: bytes
    # Attestation data
    data: AttestationData
    # Custody bitfield
    custody_bitfield: bytes
    # BLS aggregate signature
    signature: Bytes96
  */
  syntax Attestation ::= #Attestation( Bytes, AttestationData, Bytes, Bytes96 )

  /*
class AttesterSlashing(Container):
    # First attestation
    attestation_1: IndexedAttestation
    # Second attestation
    attestation_2: IndexedAttestation
  */
  syntax AttesterSlashing ::= #AttesterSlashing( IndexedAttestation, IndexedAttestation )

  /*
class BeaconBlockHeader(Container):
    slot: uint64
    parent_root: Bytes32
    state_root: Bytes32
    body_root: Bytes32
    signature: Bytes96
  */
  syntax BeaconBlockHeader ::= #BeaconBlockHeader( Slot, Bytes32, Bytes32, Bytes32, Bytes96 ) [klabel(#BeaconBlockHeader), symbol]

  /*
class Eth1Data(Container):
    # Root of the deposit tree
    deposit_root: Bytes32
    # Total number of deposits
    deposit_count: uint64
    # Block hash
    block_hash: Bytes32
  */
  syntax Eth1Data ::= #Eth1Data( Bytes32, Uint64, Bytes32 ) [klabel(#Eth1Data), symbol]


  // Python state modifying functions
  //====================================================

/*
def increase_balance(state: BeaconState, index: ValidatorIndex, delta: Gwei) -> None:
    """
    Increase validator balance by ``delta``.
    """
    state.balances[index] += delta
*/
  syntax KItem ::= "increaseBalance" "(" ValidatorIndex "," Gwei ")"
  rule <k> increaseBalance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => BAL +Int Delta) ...</balances>

/*
def decrease_balance(state: BeaconState, index: ValidatorIndex, delta: Gwei) -> None:
    """
    Decrease validator balance by ``delta`` with underflow protection.
    """
    state.balances[index] = 0 if delta > state.balances[index] else state.balances[index] - delta
*/
  syntax KItem ::= "decreaseBalance" "(" ValidatorIndex "," Gwei ")"
  rule <k> decreaseBalance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => #if Delta >Int BAL #then 0 #else BAL -Int Delta #fi) ...</balances>

/*
def process_registry_updates(state: BeaconState) -> None:
    # Process activation eligibility and ejections
    for index, validator in enumerate(state.validator_registry):
        if (
            validator.activation_eligibility_epoch == FAR_FUTURE_EPOCH and
            validator.effective_balance >= MAX_EFFECTIVE_BALANCE
        ):
            validator.activation_eligibility_epoch = get_current_epoch(state)

        if is_active_validator(validator, get_current_epoch(state)) and validator.effective_balance <= EJECTION_BALANCE:
            initiate_validator_exit(state, index)

    # Queue validators eligible for activation and not dequeued for activation prior to finalized epoch
    activation_queue = sorted([
        index for index, validator in enumerate(state.validator_registry) if
        validator.activation_eligibility_epoch != FAR_FUTURE_EPOCH and
        validator.activation_epoch >= get_delayed_activation_exit_epoch(state.finalized_epoch)
    ], key=lambda index: state.validator_registry[index].activation_eligibility_epoch)
    # Dequeued validators for activation up to churn limit (without resetting activation epoch)
    for index in activation_queue[:get_churn_limit(state)]:
        validator = state.validator_registry[index]
        if validator.activation_epoch == FAR_FUTURE_EPOCH:
            validator.activation_epoch = get_delayed_activation_exit_epoch(get_current_epoch(state))
*/
  syntax KItem ::= "processRegistryUpdates"
  rule <k> processRegistryUpdates
           => processRegistryUpdatesLoop1(VALIDATORS)
           ~> processActivationQueue()
         ...
       </k>
       <validator-registry> VALIDATORS </validator-registry>

  //we will process validators in any order, not strictly increasing index like in python
  syntax KItem ::= "processRegistryUpdatesLoop1" "(" Map ")" //validators
  rule <k> (. => #if isActiveValidator(VAL, getCurrentEpoch())
                      andBool EffBalance <=Int EJECTION_BALANCE
                    #then initiateValidatorExit(INDEX)
                    #else .K
                 #fi
           ) ~>
           processRegistryUpdatesLoop1(_:Map
                                       (INDEX |-> VAL => .Map) ) ...</k>
       <validator-registry>... INDEX |-> #Validator(_,_,
          ActEligibilityEpoch
          => #if ActEligibilityEpoch ==Int FAR_FUTURE_EPOCH
                 andBool EffBalance >=Int MAX_EFFECTIVE_BALANCE
                #then getCurrentEpoch()
                #else ActEligibilityEpoch
             #fi,
          _,_,_,_, EffBalance) ...</validator-registry>

  rule processRegistryUpdatesLoop1(.Map) => .K

  syntax KItem ::= "processActivationQueue" "("")"
                 | "processActivationQueue" "(" IntList /*activation queue*/ "," Int /*churn limit*/ ")"

  //must be done here instead of main rule, basause it must state updated by Loop1
  rule <k> processActivationQueue() => processActivationQueue(
          sortActivationQueue(getActivationQueueUnsorted(VALIDATORS, .IntList)),
          getChurnLimit() )
          ...
       </k>
       <validator-registry> VALIDATORS </validator-registry>

  rule <k> processActivationQueue(INDEX:Int IL => IL, I => I -Int 1) ... </k>
       <validator-registry>... INDEX |-> #Validator(_,_,_,
          ActEpoch => getDelayedActivationExitEpoch(getCurrentEpoch()), _,_,_,_)
          ...</validator-registry>
    requires I >Int 0
             andBool ActEpoch ==K FAR_FUTURE_EPOCH

  rule <k> processActivationQueue(INDEX:Int IL => IL, I => I -Int 1) ... </k>
       <validator-registry>... INDEX |-> #Validator(_,_,_, ActEpoch, _,_,_,_) ...</validator-registry>
    requires I >Int 0
             andBool ActEpoch =/=K FAR_FUTURE_EPOCH

  rule processActivationQueue(.IntList, _) => .K
  rule processActivationQueue(       _, 0) => .K

  /*
  index for index, validator in enumerate(state.validator_registry) if
        validator.activation_eligibility_epoch != FAR_FUTURE_EPOCH and
        validator.activation_epoch >= get_delayed_activation_exit_epoch(state.finalized_epoch) */
  syntax IntList ::= getActivationQueueUnsorted( Map /*state.validator_registry*/, IntList /*result*/ ) [function]
  rule [[ getActivationQueueUnsorted(_:Map (INDEX |-> #Validator(_,_, ActEligibilityEpoch, ActEpoch, _,_,_,_) => .Map),
                                     IL => IL INDEX) ]]
       <finalized-epoch> FinalizedEpoch </finalized-epoch>
    when ActEligibilityEpoch =/=K FAR_FUTURE_EPOCH
         andBool ActEpoch >=Int getDelayedActivationExitEpoch(FinalizedEpoch)

  rule [[ getActivationQueueUnsorted(_:Map (INDEX |-> #Validator(_,_, ActEligibilityEpoch, ActEpoch, _,_,_,_) => .Map),
                                     IL /*unchanged*/ ) ]]
       <finalized-epoch> FinalizedEpoch </finalized-epoch>
    when notBool ( ActEligibilityEpoch =/=K FAR_FUTURE_EPOCH
                   andBool ActEpoch >=Int getDelayedActivationExitEpoch(FinalizedEpoch) )

  rule getActivationQueueUnsorted(.Map, IL ) => IL

  /*activation_queue = sorted([ index for ...
    ], key=lambda index: state.validator_registry[index].activation_eligibility_epoch)*/
  syntax IntList ::= sortActivationQueue( IntList ) [function]
  rule sortActivationQueue(IL) => indexForMinEligEpoch(IL) listExcept(IL, indexForMinEligEpoch(IL))
    when IL =/=K .IntList
  rule sortActivationQueue(.IntList) => .IntList

  // min of index: state.validator_registry[index].activation_eligibility_epoch)
  syntax Int ::= indexForMinEligEpoch ( IntList )      [function]
               | indexForMinEligEpoch ( Int, IntList ) [function]
  rule indexForMinEligEpoch(I:Int IL) => indexForMinEligEpoch(I, IL)
  rule [[ indexForMinEligEpoch( MIN => #if MINActEligibilityEpoch <Int IActEligibilityEpoch #then MIN #else I #fi,
                                (I:Int IL) => IL ) ]]
    <validator-registry>
      MIN |-> #Validator(_,_, MINActEligibilityEpoch, _,_,_,_,_)
      I   |-> #Validator(_,_,   IActEligibilityEpoch, _,_,_,_,_)
      ...
    </validator-registry>
  rule indexForMinEligEpoch(MIN, .IntList) => MIN

  //returns the list except the 2nd argument. Used in sorting.
  syntax IntList ::= listExcept( IntList , Int ) [function]
                   | listExcept( IntList , Int , IntList /*result*/ ) [function]
  rule listExcept(IL, EXCEPT) => listExcept(IL, EXCEPT, .IntList)
  rule listExcept( (I:Int IL) => IL, EXCEPT, REZ => REZ I     )
    when I =/=Int EXCEPT
  rule listExcept((EXCEPT IL) => IL, EXCEPT, REZ /*unchanged*/)
  rule listExcept(         .IntList,      _, REZ) => REZ

/*
def initiate_validator_exit(state: BeaconState, index: ValidatorIndex) -> None:
    """
    Initiate the exit of the validator of the given ``index``.
    """
    # Return if validator already initiated exit
    validator = state.validator_registry[index]
    if validator.exit_epoch != FAR_FUTURE_EPOCH:
        return

    # Compute exit queue epoch
    exit_epochs = [v.exit_epoch for v in state.validator_registry if v.exit_epoch != FAR_FUTURE_EPOCH]
    exit_queue_epoch = max(exit_epochs + [get_delayed_activation_exit_epoch(get_current_epoch(state))])
    exit_queue_churn = len([v for v in state.validator_registry if v.exit_epoch == exit_queue_epoch])
    if exit_queue_churn >= get_churn_limit(state):
        exit_queue_epoch += 1

    # Set validator exit epoch and withdrawable epoch
    validator.exit_epoch = exit_queue_epoch
    validator.withdrawable_epoch = validator.exit_epoch + MIN_VALIDATOR_WITHDRAWABILITY_DELAY
*/
  syntax KItem ::= initiateValidatorExit( Int )
                 | initiateValidatorExitAux( Int /*index*/ , Epoch /*exit_queue_epoch*/ )

  rule <k> initiateValidatorExit(INDEX) => .K ...</k>
       <validator-registry>... INDEX |-> #Validator(_,_,_,_, ExitEPOCH, _,_,_) ...</validator-registry>
    when ExitEPOCH =/=K FAR_FUTURE_EPOCH

  rule <k> initiateValidatorExit(INDEX) => initiateValidatorExitAux(INDEX, exitQueueEpochAux(INDEX)) ...</k>
       <validator-registry>... INDEX |-> #Validator(_,_,_,_, ExitEPOCH, _,_,_) ...</validator-registry>

  rule <k> initiateValidatorExitAux(INDEX, ExitQEpoch) => .K ...</k>
       <validator-registry>
          (INDEX |-> #Validator(_,_,_,_,
            ExitEPOCH => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int getChurnLimit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi ,
            WithdrEpoch => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int getChurnLimit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi +Int MIN_VALIDATOR_WITHDRAWABILITY_DELAY ,
           _,_) _) #as VALIDATORS
       </validator-registry>

  syntax Epoch ::= exitQueueEpochAux ( Int ) [function]
  rule [[ exitQueueEpochAux(INDEX)
          => maxAux({getDelayedActivationExitEpoch(getCurrentEpoch())}:>Int
                    exitEpochsAux(VALIDATORS, .IntList) ) ]]
    <validator-registry> VALIDATORS </validator-registry>

  syntax IntList ::= exitEpochsAux( Map /*validators*/ , IntList /*result*/ )
  rule exitEpochsAux(_:Map (_ |-> #Validator(_,_,_, ExitEPOCH, _,_,_,_) => .Map),
                     RES => ExitEPOCH RES )
    requires ExitEPOCH =/=K FAR_FUTURE_EPOCH

  rule exitEpochsAux(_:Map (_ |-> #Validator(_,_,_, ExitEPOCH, _,_,_,_) => .Map),
                     RES /*unchanged*/ )
    requires ExitEPOCH ==K FAR_FUTURE_EPOCH

  rule exitEpochsAux(.Map, RES) => RES

  // exit_queue_churn = len([v for v in state.validator_registry if v.exit_epoch == exit_queue_epoch])
  syntax Int ::= exitQueueChurnAux ( Epoch /*exit_queue_epoch*/ , Map /*validator_registry*/ , Int /*result*/ ) [function]
  rule exitQueueChurnAux( ExitQEpoch, _:Map (_ |-> #Validator(_,_,_,_, ExitQEpoch, _,_,_) => .Map), RES => RES +Int 1 )
  rule exitQueueChurnAux( ExitQEpoch, _:Map (_ |-> #Validator(_,_,_,_, ExitEP, _,_,_) => .Map), _ )
    requires ExitEP =/=K ExitQEpoch
  rule exitQueueChurnAux( _, .Map, RES ) => RES


/* def slash_validator(state: BeaconState,
                    slashed_index: ValidatorIndex,
                    whistleblower_index: ValidatorIndex=None) -> None:
    """
    Slash the validator with index ``slashed_index``.
    """
    epoch = get_current_epoch(state)
    initiate_validator_exit(state, slashed_index)
    validator = state.validators[slashed_index]
    validator.slashed = True
    validator.withdrawable_epoch = max(validator.withdrawable_epoch, Epoch(epoch + EPOCHS_PER_SLASHINGS_VECTOR))
    state.slashings[epoch % EPOCHS_PER_SLASHINGS_VECTOR] += validator.effective_balance
    decrease_balance(state, slashed_index, validator.effective_balance // MIN_SLASHING_PENALTY_QUOTIENT)

    # Apply proposer and whistleblower rewards
    proposer_index = get_beacon_proposer_index(state)
    if whistleblower_index is None:
        whistleblower_index = proposer_index
    whistleblower_reward = Gwei(validator.effective_balance // WHISTLEBLOWER_REWARD_QUOTIENT)
    proposer_reward = Gwei(whistleblower_reward // PROPOSER_REWARD_QUOTIENT)
    increase_balance(state, proposer_index, proposer_reward)
    increase_balance(state, whistleblower_index, whistleblower_reward - proposer_reward)
*/
  syntax KItem ::= "slashValidator" "(" ValidatorIndex "," /*slashed_index*/
                                        K                  /*whistleblower_index or .K if none*/ ")"

  rule <k> slashValidator(SlashedINDEX, WhistleblINDEX)
           => initiateValidatorExit(SlashedINDEX)
           ~> slashValidatorAux(SlashedINDEX,
                                WhistleblINDEX,
                                getBeaconProposerIndex(),
                                EffBALANCE /Int WHISTLEBLOWER_REWARD_QUOTIENT, //whistleblower_reward
                                EffBALANCE /Int WHISTLEBLOWER_REWARD_QUOTIENT /Int PROPOSER_REWARD_QUOTIENT, //proposer_reward
                                {getCurrentEpoch()}:>Int +Int EPOCHS_PER_SLASHINGS_VECTOR) //SlashEPOCH
        ...</k>
       <validator-registry> SlashedINDEX |-> #Validator(_,_,_,_,_,_,_, EffBALANCE) ...</validator-registry>

  syntax KItem ::= "slashValidatorAux" "(" ValidatorIndex "," ValidatorIndex "," ValidatorIndex "," Int "," Int "," Int ")"
  rule <k> slashValidatorAux(SlashedINDEX, WhistleblINDEX, ProposerINDEX, WhistleREWARD, ProposerREWARD, SlashEPOCH)
       => decreaseBalance(SlashedINDEX, EffBALANCE /Int MIN_SLASHING_PENALTY_QUOTIENT)
       ~> increaseBalance(ProposerINDEX, ProposerREWARD)
       ~> increaseBalance(#if WhistleblINDEX ==K .ValidatorIndex #then ProposerINDEX #else WhistleblINDEX #fi,
                          WhistleREWARD -Int ProposerREWARD)
       ...</k>
    <validator-registry>
      SlashedINDEX |-> #Validator(
        _,_,_,_,_,
        WithdEPOCH => maxInt(WithdEPOCH, SlashEPOCH), //withdrawable epoch
        _ => true, //slashed
        EffBALANCE
      )
      ...
    </validator-registry>
    <slashings> SlashEPOCH |-> (SL => SL +Int EffBALANCE)  ...</slashings>


  // Python spec main functions
  //====================================================

/*
def get_beacon_proposer_index(state: BeaconState) -> ValidatorIndex:
    """
    Return the current beacon proposer index.
    """
    epoch = get_current_epoch(state)
    committees_per_slot = get_epoch_committee_count(state, epoch) // SLOTS_PER_EPOCH
    offset = committees_per_slot * (state.slot % SLOTS_PER_EPOCH)
    shard = (get_epoch_start_shard(state, epoch) + offset) % SHARD_COUNT
    first_committee = get_crosslink_committee(state, epoch, shard)
    MAX_RANDOM_BYTE = 2**8 - 1
    seed = generate_seed(state, epoch)
    i = 0
    while True:
        candidate_index = first_committee[(epoch + i) % len(first_committee)]
        random_byte = hash(seed + int_to_bytes(i // 32, length=8))[i % 32]
        effective_balance = state.validator_registry[candidate_index].effective_balance
        if effective_balance * MAX_RANDOM_BYTE >= MAX_EFFECTIVE_BALANCE * random_byte:
            return candidate_index
        i += 1
*/
  syntax ValidatorIndex ::= getBeaconProposerIndex() [function]
  rule [[ getBeaconProposerIndex()
       //=> #fun(EPOCH
       //=> #fun(CommitteesPerSlot
       //=> #fun(OFFSET
       //=> #fun(SHARD
       //=> #fun(FirstCommittee
       //=> #fun(MaxRandomByte
       //=> #fun(SEED
       //=> #fun(I
       /*=> getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD,
                                     FirstCommittee, MaxRandomByte, SEED, I)*/
       //todo commented code should work but crashes with ClassCastException, even with one #fun.
       => getBeaconProposerIndexLoop(0, 0, 0, 0, .IntList, 0, 0, 0)
          //)(0)
          //)(0/*generateSeed(EPOCH)*/)
          //)(2 ^Int 8 -Int 1)
          //)(getCrosslinkCommittee(EPOCH, SHARD))
          //)({({getEpochStartShard(EPOCH)}:>Int +Int OFFSET) %Int SHARD_COUNT}:>Shard)
          //)(CommitteesPerSlot *Int (SLOT %Int SLOTS_PER_EPOCH))
          //)(getEpochCommitteeCount(EPOCH))
          //)(getCurrentEpoch())
       ]]
    <slot> SLOT </slot>

  syntax ValidatorIndex ::= getBeaconProposerIndexLoop(
                              Epoch, Int, Int, Shard, IntList, Int, Bytes32, Int) [function]
  rule [[ getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I)
    =>    getBeaconProposerIndexLoopAux(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I,
                  get(FirstCommittee, (EPOCH +Int I) %Int len(FirstCommittee)) #as CandidateIndex,
                  getByte(hash(SEED +Int I /Int 32), I %Int 32) /*#as RandomByte*/,
                  EffectiveBalance
          ) ]]
    <validator-registry>... CandidateIndex |-> #Validator(_,_,_,_,_,_,_, EffectiveBalance) ...</validator-registry>

  syntax ValidatorIndex ::= getBeaconProposerIndexLoopAux(
                              Epoch, Int, Int, Shard, IntList, Int, Bytes32, Int,
                              Int, Int, Gwei) [function]
  rule getBeaconProposerIndexLoopAux(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I,
                                     CandidateIndex, RandomByte, EffectiveBalance)
    => getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I +Int 1)
    requires EffectiveBalance *Int MaxRandomByte <Int MAX_EFFECTIVE_BALANCE *Int RandomByte

  rule getBeaconProposerIndexLoopAux(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I,
                                     CandidateIndex, RandomByte, EffectiveBalance)
    => CandidateIndex
    requires EffectiveBalance *Int MaxRandomByte >=Int MAX_EFFECTIVE_BALANCE *Int RandomByte


  // Python spec utility functions
  //====================================================

/*
def get_base_reward(state: BeaconState, index: ValidatorIndex) -> Gwei:
    total_balance = get_total_active_balance(state)
    effective_balance = state.validator_registry[index].effective_balance
    return effective_balance * BASE_REWARD_FACTOR // integer_squareroot(total_balance) // BASE_REWARDS_PER_EPOCH
*/
  syntax Gwei ::= getBaseReward( Int ) [function]
  rule [[ getBaseReward(INDEX)
          => EffectiveBalance *Int BASE_REWARD_FACTOR
             /Int integerSquareroot({getTotalActiveBalance()}:>Int)
             /Int BASE_REWARDS_PER_EPOCH ]]
    <validator-registry> INDEX |-> #Validator(_,_,_,_,_,_,_, EffectiveBalance) </validator-registry>

/*
def get_epoch_start_shard(state: BeaconState, epoch: Epoch) -> Shard:
    assert epoch <= get_current_epoch(state) + 1
    check_epoch = get_current_epoch(state) + 1
    shard = (state.latest_start_shard + get_shard_delta(state, get_current_epoch(state))) % SHARD_COUNT
    while check_epoch > epoch:
        check_epoch -= 1
        shard = (shard + SHARD_COUNT - get_shard_delta(state, check_epoch)) % SHARD_COUNT
    return shard
*/
  syntax Shard ::= getEpochStartShard( Epoch ) [function]
  rule [[ getEpochStartShard(EPOCH) => getEpochStartShardAux(
      {{getCurrentEpoch()}:>Int +Int 1}:>Epoch,
      (LSS +Int getShardDelta(getCurrentEpoch())) %Int SHARD_COUNT,
      EPOCH
    ) ]]
    <latest-start-shard> LSS </latest-start-shard>
    requires EPOCH <=Int {getCurrentEpoch()}:>Int +Int 1

  syntax Shard ::= getEpochStartShardAux( Epoch, Shard, Epoch ) [function]
  rule getEpochStartShardAux(
      CheckEP => CheckEP -Int 1,
      SHARD => SHARD +Int SHARD_COUNT -Int getShardDelta(CheckEP -Int 1) %Int SHARD_COUNT,
      EPOCH
    )
    requires CheckEP >Int EPOCH

  rule getEpochStartShardAux(CheckEP, SHARD, EPOCH) => SHARD
    requires CheckEP <=Int EPOCH

/*
def get_previous_epoch(state: BeaconState) -> Epoch:
    """`
    Return the previous epoch of the given ``state``.
    Return the current epoch if it's genesis epoch.
    """
    current_epoch = get_current_epoch(state)
    return GENESIS_EPOCH if current_epoch == GENESIS_EPOCH else current_epoch - 1
*/
  syntax Epoch ::= getPreviousEpoch() [function]
  rule getPreviousEpoch() =>  #if getCurrentEpoch() ==K GENESIS_EPOCH
                                #then GENESIS_EPOCH
                                #else {getCurrentEpoch()}:>Int -Int 1
                              #fi

/*
def bls_domain(domain_type: int, fork_version: bytes=b'\x00\x00\x00\x00') -> int:
    """
    Return the bls domain given by the ``domain_type`` and optional 4 byte ``fork_version`` (defaults to zero).
    """
    return bytes_to_int(int_to_bytes(domain_type, length=4) + fork_version)
*/
  syntax Int ::= blsDomain(Int, Bytes32) [function]
  rule blsDomain(Domain_Type, Fork_Version) => Domain_Type +Int Fork_Version

/*
def is_active_validator(validator: Validator, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is active.
    """
    return validator.activation_epoch <= epoch < validator.exit_epoch
*/
  syntax Bool ::= isActiveValidator( Validator, Epoch ) [function]
  rule isActiveValidator( #Validator(_,_,_, ActivationEpoch, ExitEpoch, _,_,_), EPOCH )
    => ActivationEpoch <=Int EPOCH andBool EPOCH <Int ExitEpoch

/*
def get_current_epoch(state: BeaconState) -> Epoch:
    """
    Return the current epoch of the given ``state``.
    """
    return slot_to_epoch(state.slot)
*/
  syntax Epoch ::= getCurrentEpoch() [function]
  rule [[ getCurrentEpoch() => slotToEpoch(SLOT) ]]
    <slot> SLOT </slot>

/*
def get_total_balance(state: BeaconState, indices: List[ValidatorIndex]) -> Gwei:
    """
    Return the combined effective balance of the ``indices``. (1 Gwei minimum to avoid divisions by zero.)
    """
    return max(sum([state.validator_registry[index].effective_balance for index in indices]), 1)
*/
  syntax Gwei ::= getTotalBalance( IntList ) [function]
  rule getTotalBalance(INDICES) => maxInt(getTotalBalancePure(INDICES, 0), 1)

  syntax Int ::= getTotalBalancePure( IntList, Int ) [function]
  rule [[ getTotalBalancePure(I IL => IL, S => S +Int EffBalance) ]]
    <validator-registry>... I |-> #Validator(_,_,_,_,_,_,_, EffBalance) ...</validator-registry>
  rule getTotalBalancePure(.IntList, S) => S

/*
def get_epoch_start_slot(epoch: Epoch) -> Slot:
    """
    Return the starting slot of the given ``epoch``.
    """
    return epoch * SLOTS_PER_EPOCH
*/
  syntax Slot ::= getEpochStartSlot(Epoch) [function]
  rule getEpochStartSlot(EPOCH) => EPOCH *Int SLOTS_PER_EPOCH

/*
def slot_to_epoch(slot: Slot) -> Epoch:
    """
    Return the epoch number of the given ``slot``.
    """
    return slot // SLOTS_PER_EPOCH
*/
  syntax Epoch ::= slotToEpoch(Slot) [function]
  rule slotToEpoch(SLOT) => SLOT /Int SLOTS_PER_EPOCH

/*
def get_total_active_balance(state: BeaconState) -> Gwei:
    return get_total_balance(state, get_active_validator_indices(state, get_current_epoch(state)))
*/
  syntax Gwei ::= getTotalActiveBalance() [function]
  rule getTotalActiveBalance() => getTotalBalance(getActiveValidatorIndices(getCurrentEpoch()))

/*
def is_slashable_validator(validator: Validator, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is slashable.
    """
    return validator.slashed is False and (validator.activation_epoch <= epoch < validator.withdrawable_epoch)
*/
  syntax Bool ::= isSlashableValidator( Validator, Epoch ) [function]
  rule isActiveValidator( #Validator(_,_,_, ActivationEpoch, _, WithdEpoch, Slashed, _), EPOCH )
    => notBool Slashed andBool ActivationEpoch <=Int EPOCH andBool EPOCH <Int WithdEpoch

/*
def get_shard_delta(state: BeaconState, epoch: Epoch) -> int:
    """
    Return the number of shards to increment ``state.latest_start_shard`` during ``epoch``.
    """
    return min(get_epoch_committee_count(state, epoch), SHARD_COUNT - SHARD_COUNT // SLOTS_PER_EPOCH)
*/
  syntax Int ::= getShardDelta( Epoch ) [function]
  rule getShardDelta( EPOCH ) => minInt(
    getEpochCommitteeCount(EPOCH),
    SHARD_COUNT -Int SHARD_COUNT /Int SLOTS_PER_EPOCH
  )

/*
def get_active_validator_indices(state: BeaconState, epoch: Epoch) -> List[ValidatorIndex]:
    """
    Get active validator indices at ``epoch``.
    """
    return [i for i, v in enumerate(state.validator_registry) if is_active_validator(v, epoch)]
*/
  syntax IntList ::= getActiveValidatorIndices( Epoch ) [function]
  rule [[ getActiveValidatorIndices(EP) => getActiveValidatorIndicesAux(.IntList, 0, VALIDATORS, EP) ]]
    <validator-registry> VALIDATORS </validator-registry>

  syntax IntList ::= getActiveValidatorIndicesAux( IntList, Int, Map, Epoch ) [function]
  rule getActiveValidatorIndicesAux(_,          I => I +Int 1, _:Map (I |-> V => .Map), EP )
    requires notBool isActiveValidator(V, EP)
  rule getActiveValidatorIndicesAux(Is => Is I, I => I +Int 1, _:Map (I |-> V => .Map), EP )
    requires         isActiveValidator(V, EP)
  rule getActiveValidatorIndicesAux(Is, _, .Map, _) => Is

/*def get_delayed_activation_exit_epoch(epoch: Epoch) -> Epoch:
    """
    Return the epoch at which an activation or exit triggered in ``epoch`` takes effect.
    """
    return epoch + 1 + ACTIVATION_EXIT_DELAY*/
  syntax Int ::= getDelayedActivationExitEpoch ( Epoch ) [function]
  rule getDelayedActivationExitEpoch(EP) => EP +Int 1 +Int ACTIVATION_EXIT_DELAY

/*def get_churn_limit(state: BeaconState) -> int:
    """
    Return the churn limit based on the active validator count.
    """
    return max(
        MIN_PER_EPOCH_CHURN_LIMIT,
        len(get_active_validator_indices(state, get_current_epoch(state))) // CHURN_LIMIT_QUOTIENT
    )*/
  syntax Int ::= getChurnLimit( ) [function]
  rule getChurnLimit() => maxInt(
          MIN_PER_EPOCH_CHURN_LIMIT,
          len(getActiveValidatorIndices(getCurrentEpoch())) /Int CHURN_LIMIT_QUOTIENT )

/*
def get_epoch_committee_count(state: BeaconState, epoch: Epoch) -> int:
    """
    Return the number of committees at ``epoch``.
    """
    active_validator_indices = get_active_validator_indices(state, epoch)
    return max(
        1,
        min(
            SHARD_COUNT // SLOTS_PER_EPOCH,
            len(active_validator_indices) // SLOTS_PER_EPOCH // TARGET_COMMITTEE_SIZE,
        )
    ) * SLOTS_PER_EPOCH
*/
  syntax Int ::= getEpochCommitteeCount( Epoch ) [function]
  rule getEpochCommitteeCount( EP )
    => maxInt(1, minInt(SHARD_COUNT /Int SLOTS_PER_EPOCH,
                        len(getActiveValidatorIndices(EP)) /Int SLOTS_PER_EPOCH /Int TARGET_COMMITTEE_SIZE
                 )
             ) *Int SLOTS_PER_EPOCH

/*
def get_crosslink_committee(state: BeaconState, epoch: Epoch, shard: Shard) -> List[ValidatorIndex]:
    return compute_committee(
        indices=get_active_validator_indices(state, epoch),
        seed=generate_seed(state, epoch),
        index=(shard + SHARD_COUNT - get_epoch_start_shard(state, epoch)) % SHARD_COUNT,
        count=get_epoch_committee_count(state, epoch),
    )
*/
  syntax IntList ::= getCrosslinkCommittee( Epoch, Shard ) [function]
  rule getCrosslinkCommittee(EPOCH, SHARD)
    => computeCommittee(
          getActiveValidatorIndices(EPOCH),
          generateSeed(EPOCH),
          (SHARD +Int SHARD_COUNT -Int {getEpochStartShard(EPOCH)}:>Int) %Int SHARD_COUNT,
          getEpochCommitteeCount(EPOCH)
    )

/*
def compute_committee(indices: List[ValidatorIndex], seed: Bytes32, index: int, count: int) -> List[ValidatorIndex]:
    start = (len(indices) * index) // count
    end = (len(indices) * (index + 1)) // count
    return [indices[get_shuffled_index(i, len(indices), seed)] for i in range(start, end)]
*/
  syntax IntList ::= computeCommittee( IntList, Bytes32, Int, Int ) [function]
  rule computeCommittee(INDICES, SEED, INDEX, COUNT)
    => computeCommitteeLoop(
        len(INDICES) *Int INDEX,
        len(INDICES) *Int (INDEX +Int 1),
        SEED,
        INDICES,
        .IntList
    )

  syntax IntList ::= computeCommitteeLoop( Int, Int, Bytes32, IntList, IntList )
  rule computeCommitteeLoop(I => I +Int 1, END, SEED, INDICES,
                            RESULT => RESULT getShuffledIndex(I, len(INDICES), SEED))
    requires I <Int END
  rule computeCommitteeLoop(I, END, _,_, RESULT) => RESULT
    requires I >=Int END

/*
def get_shuffled_index(index: ValidatorIndex, index_count: int, seed: Bytes32) -> ValidatorIndex
*/
  syntax Int ::= getShuffledIndex( Int, Int, Bytes32 ) [function]
  rule getShuffledIndex(INDEX, COUNT, SEED) => INDEX %Int COUNT //NOTEH mock implementation

/*
def generate_seed(state: BeaconState,
                  epoch: Epoch) -> Bytes32:
*/
  syntax Bytes32 ::= generateSeed( Epoch ) [function]
  rule generateSeed(_) => 0 //NOTEH mock implementation for now

/*
def xor(bytes1: Bytes32, bytes2: Bytes32) -> Bytes32:
    return Bytes32(a ^ b for a, b in zip(bytes1, bytes2))
*/
  syntax Bytes32 ::= xor( Bytes32, Bytes32 ) [function]
  rule xor(A,B) => A xorInt B

  // Python framework functions
  //====================================================
  syntax Int ::= len( IntList ) [function]
  rule len( _:Int L) => 1 +Int len(L)
  rule len(.IntList) => 0

  syntax Int ::= get( IntList, Int ) [function]
  rule get( _:Int L => L, I => I -Int 1)
    requires I >Int 0
  rule get( ELEM _:IntList, 0) => ELEM

  syntax Int ::= sum( IntList ) [function]
  rule sum( IL ) => sumAux(IL, 0)

  syntax Int ::= sumAux( IntList, Int ) [function]
  rule sumAux(I:Int IL => IL, S => S +Int I)
  rule sumAux(.IntList, S) => S

  syntax Int ::= maxAux ( IntList ) [function]
               | maxAux ( IntList , Int ) [function]
  rule maxAux( I:Int IL ) => maxAux(IL, I)
  rule maxAux(I IL => IL, MAX => #if I <Int MAX #then MAX #else I #fi )
  rule maxAux(.IntList, MAX) => MAX

  //first argument is a result of hash(), e.g. a 256-bit number.
  syntax Int ::= getByte(Bytes, Int) [function]
  rule getByte(BYTES, I) => Bytes2Int(substrBytes(BYTES, I, I), BE, Unsigned)
  //todo question: what endianness should we use above?

  syntax Bytes ::= hash( Int ) [function] //todo implement

  syntax Int ::= integerSquareroot( Int ) [function] //todo implement

endmodule
