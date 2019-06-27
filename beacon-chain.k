module BEACON-CHAIN
  imports DOMAINS

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
      </state>
      <block>                           //Type BeaconBlock in python spec.
        <blockSlot> -1 </blockSlot>
        <parent-root> -1 </parent-root>
        <state-root> -1 </state-root>
        <body>                          //Type BeaconBlockBody in python spec.
          <randao-reveal> -1 </randao-reveal>
          <eth1-data> .Eth1Data </eth1-data>
          <graffiti> -1 </graffiti>
          <proposer-slashings> .ProposerSlashingList </proposer-slashings>
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
  syntax BlockHeader ::= ".BlockHeader"
  syntax Eth1Data ::= ".Eth1Data"

  syntax Bytes ::= #Bytes( Int, Int ) //DATA, LEN
  syntax Uint64 ::= Int

  syntax Uint64List ::= List{Uint64, ""}
  syntax Bytes32List ::= List{Bytes32, ""}
  syntax ProposerSlashingList ::= List{ProposerSlashing, ""}
  syntax AttesterSlashingList ::= List{AttesterSlashing, ""}
  syntax AttestationList ::= List{Attestation, ""}
  syntax DepositList ::= List{Deposit, ""}
  syntax VoluntaryExitList ::= List{VoluntaryExit, ""}
  syntax TransferList ::= List{Transfer, ""}
  syntax CrosslinkList ::= List{Crosslink, ""}
  syntax Eth1DataList ::= List{Eth1Data, ""}
  syntax ValidatorList ::= List{Validator, ""}
  syntax PendingAttestationList ::= List{PendingAttestation, ""}
  syntax IntList ::= List{Int, ""}

  // Python spec types
  //====================================================
  syntax Slot ::= Int
  syntax Epoch ::= Int
  syntax Shard ::= Int
  syntax ValidatorIndex ::= Int
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
  syntax Int ::= "LATEST_RANDAO_MIXES_LENGTH"
  rule LATEST_RANDAO_MIXES_LENGTH => 2 ^Int 13                [macro]
  syntax Int ::= "LATEST_ACTIVE_INDEX_ROOTS_LENGTH"
  rule LATEST_ACTIVE_INDEX_ROOTS_LENGTH => 2 ^Int 13          [macro]
  syntax Int ::= "LATEST_SLASHED_EXIT_LENGTH"
  rule LATEST_SLASHED_EXIT_LENGTH => 2 ^Int 13                [macro]
  syntax Int ::= "BASE_REWARD_FACTOR"
  rule BASE_REWARD_FACTOR => 2 ^Int 5                         [macro]
  syntax Int ::= "WHISTLEBLOWING_REWARD_QUOTIENT"
  rule WHISTLEBLOWING_REWARD_QUOTIENT => 2 ^Int 9             [macro]
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
  syntax Fork ::= #Fork( Bytes4, Bytes4, Epoch )

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
  syntax Crosslink ::= #Crosslink( Shard, Epoch, Epoch, Bytes32, Bytes32 )

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
  syntax Validator ::= #Validator( Bytes48, Bytes32, Epoch, Epoch, Epoch, Epoch, Bool, Uint64 )

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
  syntax PendingAttestation ::= #PendingAttestation( Bytes, AttestationData, Uint64, Uint64 )

  /*
class Deposit(Container):
    # Branch in the deposit tree
    proof: Vector[Bytes32, DEPOSIT_CONTRACT_TREE_DEPTH]
    # Data
    data: DepositData
  */
  syntax Deposit ::= #Deposit( Bytes32List, DepositData )

  /*
class ProposerSlashing(Container):
    # Proposer index
    proposer_index: uint64
    # First block header
    header_1: BeaconBlockHeader
    # Second block header
    header_2: BeaconBlockHeader
  */
  syntax ProposerSlashing ::= #ProposerSlashing( Uint64, BeaconBlockHeader, BeaconBlockHeader )

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
  syntax AttestationData ::= #AttestationData( Bytes32, Epoch, Bytes32, Epoch, Bytes32, Crosslink )

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
  syntax BeaconBlockHeader ::= #BeaconBlockHeader( Slot, Bytes32, Bytes32, Bytes32, Bytes96 )

  /*
class Eth1Data(Container):
    # Root of the deposit tree
    deposit_root: Bytes32
    # Total number of deposits
    deposit_count: uint64
    # Block hash
    block_hash: Bytes32
  */
  syntax Eth1Data ::= #Eth1Data( Bytes32, Uint64, Bytes32 )


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
//todo stopped here


  // Python spec utility functions
  //====================================================

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

  syntax Int ::= sum( IntList ) [function]
  rule sum( IL ) => sumAux(IL, 0)

  syntax Int ::= sumAux( IntList, Int ) [function]
  rule sumAux(I:Int IL => IL, S => S +Int I)
  rule sumAux(.IntList, S) => S


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

endmodule
