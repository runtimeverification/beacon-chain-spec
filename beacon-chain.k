module BEACON-CHAIN
  imports DOMAINS
  imports BYTES-HOOKED

/*
class BeaconState(Container):
    # Versioning
    genesis_time: uint64
    slot: Slot
    fork: Fork
    # History
    latest_block_header: BeaconBlockHeader
    block_roots: Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
    state_roots: Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
    historical_roots: List[Hash, HISTORICAL_ROOTS_LIMIT]
    # Eth1
    eth1_data: Eth1Data
    eth1_data_votes: List[Eth1Data, SLOTS_PER_ETH1_VOTING_PERIOD]
    eth1_deposit_index: uint64
    # Registry
    validators: List[Validator, VALIDATOR_REGISTRY_LIMIT]
    balances: List[Gwei, VALIDATOR_REGISTRY_LIMIT]
    # Shuffling
    start_shard: Shard
    randao_mixes: Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]
    active_index_roots: Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]  # Active index digests for light clients
    compact_committees_roots: Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]  # Committee digests for light clients
    # Slashings
    slashings: Vector[Gwei, EPOCHS_PER_SLASHINGS_VECTOR]  # Per-epoch sums of slashed effective balances
    # Attestations
    previous_epoch_attestations: List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
    current_epoch_attestations: List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
    # Crosslinks
    previous_crosslinks: Vector[Crosslink, SHARD_COUNT]  # Previous epoch snapshot
    current_crosslinks: Vector[Crosslink, SHARD_COUNT]
    # Finality
    justification_bits: Bitvector[JUSTIFICATION_BITS_LENGTH]  # Bit set for every recent justified epoch
    previous_justified_checkpoint: Checkpoint  # Previous epoch snapshot
    current_justified_checkpoint: Checkpoint
    finalized_checkpoint: Checkpoint

class BeaconBlock(Container):
    slot: Slot
    parent_root: Hash
    state_root: Hash
    body: BeaconBlockBody
    signature: BLSSignature

class BeaconBlockBody(Container):
    randao_reveal: BLSSignature
    eth1_data: Eth1Data  # Eth1 data vote
    graffiti: Bytes32  # Arbitrary data
    # Operations
    proposer_slashings: List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
    attester_slashings: List[AttesterSlashing, MAX_ATTESTER_SLASHINGS]
    attestations: List[Attestation, MAX_ATTESTATIONS]
    deposits: List[Deposit, MAX_DEPOSITS]
    voluntary_exits: List[VoluntaryExit, MAX_VOLUNTARY_EXITS]
    transfers: List[Transfer, MAX_TRANSFERS]
*/
    // TODO: Add appropriate constraints on lists below
  configuration
    <beacon-chain>
      <k> $PGM:Pgm </k>
      <state>                           //Type BeaconState in python spec.
        // Versioning
        <genesis-time> 0 </genesis-time>
        <slot> 0 </slot>
        <fork> .Fork </fork>
        // History
        <latest-block-header> .BlockHeader </latest-block-header>
        <block-roots> .HashList </block-roots> //Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
        <state-roots> .HashList </state-roots> //Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
        <historical-roots> .HashList </historical-roots> //List[Hash, HISTORICAL_ROOTS_LIMIT]
        // Eth1
        <eth1-data> .Eth1Data </eth1-data>
        <eth1-data-votes> .Eth1DataList </eth1-data-votes> //List[Eth1Data, SLOTS_PER_ETH1_VOTING_PERIOD]
        <eth1-deposit-index> 0 </eth1-deposit-index>
        // Registry
        <validators> .Map </validators> //List[Validator, VALIDATOR_REGISTRY_LIMIT]
        <balances> .Map </balances> //List[Gwei, VALIDATOR_REGISTRY_LIMIT]
        // Shuffling
        <start-shard> 0 </start-shard>
        <randao-mixes> .HashList </randao-mixes> //Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]
        <active-index-roots> .HashList </active-index-roots> //Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]
        <compact-committees-roots> .HashList </compact-committees-roots> //Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]
        // Slashings
        <slashings> .GweiList </slashings> //Vector[Gwei, EPOCHS_PER_SLASHINGS_VECTOR]
        // Attestations
        <previous-epoch-attestations> .PendingAttestationList </previous-epoch-attestations>
                                                       //List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
        <current-epoch-attestations> .PendingAttestationList </current-epoch-attestations>
                                                       //List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
        // Crosslinks
        <previous-crosslinks> .CrosslinkList </previous-crosslinks> //Vector[Crosslink, SHARD_COUNT]
        <current-crosslinks> .CrosslinkList </current-crosslinks> //Vector[Crosslink, SHARD_COUNT]
        // Finality
        <justification-bits> .BitList </justification-bits> //Bitvector[JUSTIFICATION_BITS_LENGTH]
        <previous-justified-checkpoint> .Checkpoint </previous-justified-checkpoint>
        <current-justified-checkpoint> .Checkpoint </current-justified-checkpoint>
        <finalized-checkpoint> .Checkpoint </finalized-checkpoint>
      </state>
      <block>                           //Type BeaconBlock in python spec.
        <blockSlot> -1 </blockSlot>
        <parent-root> -1 </parent-root>
        <state-root> -1 </state-root>
        <body>                          //Type BeaconBlockBody in python spec.
          <randao-reveal> -1 </randao-reveal>
          <eth1-data> .Eth1Data </eth1-data>
          <graffiti> -1 </graffiti>
          <proposer-slashings> .ProposerSlashingList </proposer-slashings> //List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
          <attester-slashings> .AttesterSlashingList </attester-slashings> //List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
          <attestations> .AttestationList </attestations> //List[Attestation, MAX_ATTESTATIONS]
          <deposits> .DepositList </deposits> //List[Deposit, MAX_DEPOSITS]
          <voluntary-exits> .VoluntaryExitList </voluntary-exits> //List[VoluntaryExit, MAX_VOLUNTARY_EXITS]
          <transfers> .TransferList </transfers> //List[Transfer, MAX_TRANSFERS]
        </body>
        <signature> -1 </signature>
      </block>
    </beacon-chain>

  syntax KItem ::= Pgm
  syntax Pgm ::= ".Pgm"
  syntax Fork ::= ".Fork"
  syntax BlockHeader ::= ".BlockHeader"
  syntax Eth1Data ::= ".Eth1Data"
  syntax Checkpoint ::= ".Checkpoint"

  // Basic Python (SSZ) types
  //====================================================
  syntax Bytes   ::= #Bytes( Int, Int ) //DATA, LEN
  syntax Uint64  ::= Int
  syntax Bytes4  ::= Int
  syntax Bytes8  ::= Int
  syntax Bytes32 ::= Int
  syntax Bytes48 ::= Int
  syntax Bytes96 ::= Int
  syntax Bit     ::= Int

  // Custom types
  //====================================================
  syntax Slot           ::= Uint64      //a slot number
  syntax Epoch          ::= Uint64      //an epoch number
  syntax Shard          ::= Uint64      //a shard number
  syntax ValidatorIndex ::= Uint64      //a validator registry index
  syntax Gwei           ::= Uint64      //an amount in Gwei
  syntax Hash           ::= Bytes32     //a hash
  syntax Version        ::= Bytes4      //a fork version number
  syntax DomainType     ::= Bytes4      //a signature domain type
  syntax Domain         ::= Bytes8      //a signature domain
  syntax BLSPubkey      ::= Bytes48     //a BLS12-381 public key
  syntax BLSSignature   ::= Bytes96     //a BLS12-381 signature

  // List types
  //====================================================
  syntax Uint64List ::= List{Uint64, ""}
  syntax Bytes32List ::= List{Bytes32, ""}
  syntax Bytes48List ::= List{Bytes48, ""}
  syntax ProposerSlashingList ::= List{ProposerSlashing, ""}
  syntax AttesterSlashingList ::= List{AttesterSlashing, ""}
  syntax AttestationList ::= List{Attestation, ""}
  syntax DepositList ::= List{Deposit, ""}
  syntax VoluntaryExitList ::= List{VoluntaryExit, ""}
  syntax TransferList ::= List{Transfer, ""}
  syntax CrosslinkList ::= List{Crosslink, ""}
  syntax Eth1DataList ::= List{Eth1Data, ""}
  syntax PendingAttestationList ::= List{PendingAttestation, ""}
  syntax ValidatorIndexList ::= List{ValidatorIndex, ""}
  syntax IntList ::= List{Int, ""}
  syntax BitList ::= List{Bit, ""}
  syntax GweiList ::= List{Gwei, ""}
  syntax HashList ::= List{Hash, ""}

  // (Non-configurable) constants
  //====================================================
  syntax Int ::= "FAR_FUTURE_EPOCH"
  rule FAR_FUTURE_EPOCH => 2 ^Int 64 -Int 1                   [macro]
  syntax Int ::= "BASE_REWARDS_PER_EPOCH"
  rule BASE_REWARDS_PER_EPOCH => 5                            [macro]
  syntax Int ::= "DEPOSIT_CONTRACT_TREE_DEPTH"
  rule DEPOSIT_CONTRACT_TREE_DEPTH => 2 ^Int 5                [macro]
  syntax Int ::= "SECONDS_PER_DAY"
  rule SECONDS_PER_DAY => 86400                               [macro]
  syntax Int ::= "JUSTIFICATION_BITS_LENGTH"
  rule JUSTIFICATION_BITS_LENGTH => 4                         [macro]
  syntax String ::= "ENDIANNESS"
  rule ENDIANNESS => "little"                                 [macro]

  // Configuration -- Misc
  //====================================================
  syntax Int ::= "SHARD_COUNT"
  rule SHARD_COUNT => 2 ^Int 10                               [macro]
  syntax Int ::= "TARGET_COMMITTEE_SIZE"
  rule TARGET_COMMITTEE_SIZE => 2 ^Int 7                      [macro]
  syntax Int ::= "MAX_VALIDATORS_PER_COMMITTEE"
  rule MAX_VALIDATORS_PER_COMMITTEE => 2 ^Int 12              [macro]
  syntax Int ::= "MIN_PER_EPOCH_CHURN_LIMIT"
  rule MIN_PER_EPOCH_CHURN_LIMIT => 2 ^Int 2                  [macro]
  syntax Int ::= "CHURN_LIMIT_QUOTIENT"
  rule CHURN_LIMIT_QUOTIENT => 2 ^Int 16                      [macro]
  syntax Int ::= "SHUFFLE_ROUND_COUNT"
  rule SHUFFLE_ROUND_COUNT => 90                              [macro]
  syntax Int ::= "MIN_GENESIS_ACTIVE_VALIDATOR_COUNT"
  rule MIN_GENESIS_ACTIVE_VALIDATOR_COUNT => 2 ^Int 16        [macro]
  syntax Int ::= "MIN_GENESIS_TIME"
  rule MIN_GENESIS_TIME => 1578009600                         [macro]

  // Configuration -- Gwei values
  //====================================================
  syntax Int ::= "MIN_DEPOSIT_AMOUNT"
  rule MIN_DEPOSIT_AMOUNT => 2 ^Int 0 *Int 10 ^Int 9          [macro]
  syntax Int ::= "MAX_EFFECTIVE_BALANCE"
  rule MAX_EFFECTIVE_BALANCE => 2 ^Int 5 *Int 10 ^Int 9       [macro]
  syntax Int ::= "EJECTION_BALANCE"
  rule EJECTION_BALANCE => 2 ^Int 4 *Int 10 ^Int 9            [macro]
  syntax Int ::= "EFFECTIVE_BALANCE_INCREMENT"
  rule EFFECTIVE_BALANCE_INCREMENT => 2 ^Int 0 *Int 10 ^Int 9 [macro]

  // Configuration -- Initial values
  //====================================================
  syntax Int ::= "GENESIS_SLOT"
  rule GENESIS_SLOT => 0                                      [macro]
  syntax Int ::= "GENESIS_EPOCH"
  rule GENESIS_EPOCH => 0                                     [macro]
  syntax Int ::= "BLS_WITHDRAWAL_PREFIX"
  rule BLS_WITHDRAWAL_PREFIX => 0                             [macro]

  // Configuration -- Time parameters
  //====================================================
  syntax Int ::= "MIN_ATTESTATION_INCLUSION_DELAY"
  rule MIN_ATTESTATION_INCLUSION_DELAY => 2 ^Int 0            [macro]
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

  // Configuration -- State list lengths
  //====================================================
  syntax Int ::= "EPOCHS_PER_HISTORICAL_VECTOR"
  rule EPOCHS_PER_HISTORICAL_VECTOR => 2 ^Int 16              [macro]
  syntax Int ::= "EPOCHS_PER_SLASHINGS_VECTOR"
  rule EPOCHS_PER_SLASHINGS_VECTOR => 2 ^Int 13               [macro]
  syntax Int ::= "HISTORICAL_ROOTS_LIMIT"
  rule HISTORICAL_ROOTS_LIMIT => 2 ^Int 24                    [macro]
  syntax Int ::= "VALIDATOR_REGISTRY_LIMIT"
  rule VALIDATOR_REGISTRY_LIMIT => 2 ^Int 40                  [macro]

  // Configuration -- Rewards and penalties
  //====================================================
  syntax Int ::= "BASE_REWARD_FACTOR"
  rule BASE_REWARD_FACTOR => 2 ^Int 6                         [macro]
  syntax Int ::= "WHISTLEBLOWER_REWARD_QUOTIENT"
  rule WHISTLEBLOWER_REWARD_QUOTIENT => 2 ^Int 9             [macro]
  syntax Int ::= "PROPOSER_REWARD_QUOTIENT"
  rule PROPOSER_REWARD_QUOTIENT => 2 ^Int 3                   [macro]
  syntax Int ::= "INACTIVITY_PENALTY_QUOTIENT"
  rule INACTIVITY_PENALTY_QUOTIENT => 2 ^Int 25               [macro]
  syntax Int ::= "MIN_SLASHING_PENALTY_QUOTIENT"
  rule MIN_SLASHING_PENALTY_QUOTIENT => 2 ^Int 5              [macro]

  // Configuration -- Max operations per block
  //====================================================
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

  // Configuration -- Signature domain types
  //====================================================
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

  // Containers
  //====================================================
  /*
class Fork(Container):
    previous_version: Version
    current_version: Version
    epoch: Epoch  # Epoch of latest fork
  */
  syntax Fork ::= #Fork( Version, Version, Epoch )

  /*
class Checkpoint(Container):
    epoch: Epoch
    root: Hash
  */
  syntax Checkpoint ::= #Checkpoint( Epoch, Hash )

  /*
class Validator(Container):
    pubkey: BLSPubkey
    withdrawal_credentials: Hash  # Commitment to pubkey for withdrawals and transfers
    effective_balance: Gwei  # Balance at stake
    slashed: boolean
    # Status epochs
    activation_eligibility_epoch: Epoch  # When criteria for activation were met
    activation_epoch: Epoch
    exit_epoch: Epoch
    withdrawable_epoch: Epoch  # When validator can withdraw or transfer funds
  */
  syntax Validator ::= #Validator( BLSPubkey, Hash, Gwei, Bool, Epoch, Epoch, Epoch, Epoch )

  /*
class Crosslink(Container):
    shard: Shard
    parent_root: Hash
    # Crosslinking data
    start_epoch: Epoch
    end_epoch: Epoch
    data_root: Hash
  */
  syntax Crosslink ::= #Crosslink( Shard, Hash, Epoch, Epoch, Hash )

  /*
class AttestationData(Container):
    # LMD GHOST vote
    beacon_block_root: Hash
    # FFG vote
    source: Checkpoint
    target: Checkpoint
    # Crosslink vote
    crosslink: Crosslink
  */
  syntax AttestationData ::= #AttestationData( Hash, Checkpoint, Checkpoint, Crosslink )

  /*
class AttestationDataAndCustodyBit(Container):
    data: AttestationData
    custody_bit: bit  # Challengeable bit (SSZ-bool, 1 byte) for the custody of crosslink data
  */
  syntax AttestationDataAndCustodyBit ::= #AttestationDataAndCustodyBit( AttestationData, Bit )

  /*
class IndexedAttestation(Container):
    custody_bit_0_indices: List[ValidatorIndex, MAX_VALIDATORS_PER_COMMITTEE]  # Indices with custody bit equal to 0
    custody_bit_1_indices: List[ValidatorIndex, MAX_VALIDATORS_PER_COMMITTEE]  # Indices with custody bit equal to 1
    data: AttestationData
    signature: BLSSignature
  */
  // TODO: Add constraint on length of ValidatorIndexList (MAX_VALIDATORS_PER_COMMITTEE)
  syntax IndexedAttestation ::= #IndexedAttestation( ValidatorIndexList, ValidatorIndexList, AttestationData, BLSSignature )

  /*
class PendingAttestation(Container):
    aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
    data: AttestationData
    inclusion_delay: Slot
    proposer_index: ValidatorIndex
  */
  // TODO: Add constraint on length of BitList (MAX_VALIDATORS_PER_COMMITTEE)
  syntax PendingAttestation ::= #PendingAttestation( BitList, AttestationData, Slot, ValidatorIndex )

  /*
class Eth1Data(Container):
    deposit_root: Hash
    deposit_count: uint64
    block_hash: Hash
  */
  syntax Eth1Data ::= #Eth1Data( Hash, Uint64, Hash )

  /*
class HistoricalBatch(Container):
    block_roots: Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
    state_roots: Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
  */
  // TODO: Add constraint on length of HashList (SLOTS_PER_HISTORICAL_ROOT)
  syntax HistoricalBatch ::= #HistoricalBatch( HashList, HashList )

  /*
class DepositData(Container):
    pubkey: BLSPubkey
    withdrawal_credentials: Hash
    amount: Gwei
    signature: BLSSignature
  */
  syntax DepositData ::= #DepositData( BLSPubkey, Hash, Gwei, BLSSignature )

  /*
class CompactCommittee(Container):
    pubkeys: List[Bytes48, MAX_VALIDATORS_PER_COMMITTEE]
    compact_validators: List[uint64, MAX_VALIDATORS_PER_COMMITTEE]
  */
  // TODO: Add constraint on length of Bytes48List (MAX_VALIDATORS_PER_COMMITTEE)
  // TODO: Add constraint on length of uint64List (MAX_VALIDATORS_PER_COMMITTEE)
  syntax CompactCommittee ::= #CompactCommittee( Bytes48List, Uint64List )

  /*
class BeaconBlockHeader(Container):
    slot: Slot
    parent_root: Hash
    state_root: Hash
    body_root: Hash
    signature: BLSSignature
  */
  syntax BeaconBlockHeader ::= #BeaconBlockHeader( Slot, Hash, Hash, Hash, BLSSignature )

  /*
class ProposerSlashing(Container):
    proposer_index: ValidatorIndex
    header_1: BeaconBlockHeader
    header_2: BeaconBlockHeader
  */
  syntax ProposerSlashing ::= #ProposerSlashing( ValidatorIndex, BeaconBlockHeader, BeaconBlockHeader )

  /*
class AttesterSlashing(Container):
    attestation_1: IndexedAttestation
    attestation_2: IndexedAttestation
  */
  syntax AttesterSlashing ::= #AttesterSlashing( IndexedAttestation, IndexedAttestation )

  /*
class Attestation(Container):
    aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
    data: AttestationData
    custody_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
    signature: BLSSignature
  */
  // TODO: Add constraint on lengths of both BitList lists (MAX_VALIDATORS_PER_COMMITTEE)
  syntax Attestation ::= #Attestation( BitList, AttestationData, BitList, BLSSignature )

  /*
class Deposit(Container):
    proof: Vector[Hash, DEPOSIT_CONTRACT_TREE_DEPTH + 1]  # Merkle path to deposit data list root
    data: DepositData
  */
  // TODO: Add constraint on length of HashList (DEPOSIT_CONTRACT_TREE_DEPTH + 1)
  syntax Deposit ::= #Deposit( HashList, DepositData )

  /*
class VoluntaryExit(Container):
    epoch: Epoch  # Earliest epoch when voluntary exit can be processed
    validator_index: ValidatorIndex
    signature: BLSSignature
  */
  syntax VoluntaryExit ::= #VoluntaryExit( Epoch, ValidatorIndex, BLSSignature )

  /*
class Transfer(Container):
    sender: ValidatorIndex
    recipient: ValidatorIndex
    amount: Gwei
    fee: Gwei
    slot: Slot  # Slot at which transfer must be processed
    pubkey: BLSPubkey  # Withdrawal pubkey
    signature: BLSSignature  # Signature checked against withdrawal pubkey
  */
  syntax Transfer ::= #Transfer( ValidatorIndex, ValidatorIndex, Gwei, Gwei, Slot, BLSPubkey, BLSSignature )

  // Helper functions -- Math
  //====================================================
/*
def int_to_bytes(n: uint64, length: uint64) -> bytes:
    """
    Return the ``length``-byte serialization of ``n``.
    """
    return n.to_bytes(length, ENDIANNESS)
*/
  syntax Bytes ::= intToBytes( Int ) [function] 

/*
def bytes_to_int(data: bytes) -> uint64:
    """
    Return the integer deserialization of ``data``.
    """
    return int.from_bytes(data, ENDIANNESS)
*/
  syntax Int ::= bytesToInt( Bytes ) [function] 

  syntax Int ::= integerSquareroot( Int ) [function] 

/*
def xor(bytes1: Bytes32, bytes2: Bytes32) -> Bytes32:
    return Bytes32(a ^ b for a, b in zip(bytes1, bytes2))
*/
  syntax Bytes32 ::= xor( Bytes32, Bytes32 ) [function]
  rule xor(A,B) => A xorInt B

  // Helper functions -- Crypto
  //====================================================
/*
def hash(data: bytes) -> Hash is SHA256.
*/
  syntax Bytes ::= hash( Bytes ) [function] 

/*
def hash_tree_root(object: SSZSerializable) -> Hash
*/
  syntax Bytes ::= hashTreeRoot( Bytes ) [function] 

/*
def signing_root(object: Container) -> Hash
 */

/*
bls_verify is a function for verifying a BLS signature
*/

/*
bls_verify_multiple is a function for verifying a BLS signature constructed from multiple messages
*/

/*
bls_aggregate_pubkeys is a function for aggregating multiple BLS public keys into a single aggregate key
*/

  // Helper functions -- Predicates
  //====================================================
/*
def is_active_validator(validator: Validator, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is active.
    """
    return validator.activation_epoch <= epoch < validator.exit_epoch
*/
  syntax Bool ::= isActiveValidator( Validator, Epoch ) [function]
  rule isActiveValidator( #Validator(_,_,_,_,_, ActivationEpoch, ExitEpoch, _), EPOCH )
    => ActivationEpoch <=Int EPOCH andBool EPOCH <Int ExitEpoch

/*
def is_slashable_validator(validator: Validator, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is slashable.
    """
    return (not validator.slashed) and (validator.activation_epoch <= epoch < validator.withdrawable_epoch)
*/
  syntax Bool ::= isSlashableValidator( Validator, Epoch ) [function]
  rule isActiveValidator( #Validator(_,_,_, ActivationEpoch, _, WithdEpoch, Slashed, _), EPOCH )
    => notBool Slashed>Bool andBool ActivationEpoch <=Int EPOCH andBool EPOCH <Int WithdEpoch

/*
def is_slashable_attestation_data(data_1: AttestationData, data_2: AttestationData) -> bool:
    """
    Check if ``data_1`` and ``data_2`` are slashable according to Casper FFG rules.
    """
    return (
        # Double vote
        (data_1 != data_2 and data_1.target.epoch == data_2.target.epoch) or
        # Surround vote
        (data_1.source.epoch < data_2.source.epoch and data_2.target.epoch < data_1.target.epoch)
    )
*/
// 

/*
def is_valid_indexed_attestation(state: BeaconState, indexed_attestation: IndexedAttestation) -> bool:
    """
    Verify validity of ``indexed_attestation``.
    """
    bit_0_indices = indexed_attestation.custody_bit_0_indices
    bit_1_indices = indexed_attestation.custody_bit_1_indices

    # Verify no index has custody bit equal to 1 [to be removed in phase 1]
    if not len(bit_1_indices) == 0:
        return False
    # Verify max number of indices
    if not len(bit_0_indices) + len(bit_1_indices) <= MAX_VALIDATORS_PER_COMMITTEE:
        return False
    # Verify index sets are disjoint
    if not len(set(bit_0_indices).intersection(bit_1_indices)) == 0:
        return False
    # Verify indices are sorted
    if not (bit_0_indices == sorted(bit_0_indices) and bit_1_indices == sorted(bit_1_indices)):
        return False
    # Verify aggregate signature
    if not bls_verify_multiple(
        pubkeys=[
            bls_aggregate_pubkeys([state.validators[i].pubkey for i in bit_0_indices]),
            bls_aggregate_pubkeys([state.validators[i].pubkey for i in bit_1_indices]),
        ],
        message_hashes=[
            hash_tree_root(AttestationDataAndCustodyBit(data=indexed_attestation.data, custody_bit=0b0)),
            hash_tree_root(AttestationDataAndCustodyBit(data=indexed_attestation.data, custody_bit=0b1)),
        ],
        signature=indexed_attestation.signature,
        domain=get_domain(state, DOMAIN_ATTESTATION, indexed_attestation.data.target.epoch),
    ):
        return False
    return True
*/
// 

/*
def is_valid_merkle_branch(leaf: Hash, branch: Sequence[Hash], depth: uint64, index: uint64, root: Hash) -> bool:
    """
    Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
    """
    value = leaf
    for i in range(depth):
        if index // (2**i) % 2:
            value = hash(branch[i] + value)
        else:
            value = hash(value + branch[i])
    return value == root
*/
// 

  // Helper functions -- Misc
  //====================================================

/*
def compute_shuffled_index(index: ValidatorIndex, index_count: uint64, seed: Hash) -> ValidatorIndex:
    """
    Return the shuffled validator index corresponding to ``seed`` (and ``index_count``).
    """
    assert index < index_count

    # Swap or not (https://link.springer.com/content/pdf/10.1007%2F978-3-642-32009-5_1.pdf)
    # See the 'generalized domain' algorithm on page 3
    for current_round in range(SHUFFLE_ROUND_COUNT):
        pivot = bytes_to_int(hash(seed + int_to_bytes(current_round, length=1))[0:8]) % index_count
        flip = ValidatorIndex((pivot + index_count - index) % index_count)
        position = max(index, flip)
        source = hash(seed + int_to_bytes(current_round, length=1) + int_to_bytes(position // 256, length=4))
        byte = source[(position % 256) // 8]
        bit = (byte >> (position % 8)) % 2
        index = flip if bit else index

    return ValidatorIndex(index)
*/
// 
  syntax Int ::= computeShuffledIndex( Int, Int, Bytes32 ) [function]
  rule computeShuffledIndex(INDEX, COUNT, SEED) => INDEX %Int COUNT //NOTEH mock implementation


/*
def compute_committee(indices: Sequence[ValidatorIndex],
                      seed: Hash,
                      index: uint64,
                      count: uint64) -> Sequence[ValidatorIndex]:
    """
    Return the committee corresponding to ``indices``, ``seed``, ``index``, and committee ``count``.
    """
    start = (len(indices) * index) // count
    end = (len(indices) * (index + 1)) // count
    return [indices[compute_shuffled_index(ValidatorIndex(i), len(indices), seed)] for i in range(start, end)]
*/
  syntax IntList ::= computeCommittee( IntList, Hash, Int, Int ) [function]
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
                            RESULT => RESULT computeShuffledIndex(I, len(INDICES), SEED))
    requires I <Int END
  rule computeCommitteeLoop(I, END, _,_, RESULT) => RESULT
    requires I >=Int END

/*
def compute_epoch_of_slot(slot: Slot) -> Epoch:
    """
    Return the epoch number of ``slot``.
    """
    return Epoch(slot // SLOTS_PER_EPOCH)
*/
  syntax Epoch ::= computeEpochOfSlot(Slot) [function]
  rule computeEpochOfSlot(SLOT) => SLOT /Int SLOTS_PER_EPOCH

/*
def compute_start_slot_of_epoch(epoch: Epoch) -> Slot:
    """
    Return the start slot of ``epoch``.
    """
    return Slot(epoch * SLOTS_PER_EPOCH)
*/
  syntax Slot ::= computeStartSlotOfEpoch(Epoch) [function]
  rule computeStartSlotOfEpoch(EPOCH) => EPOCH *Int SLOTS_PER_EPOCH

/*
def compute_activation_exit_epoch(epoch: Epoch) -> Epoch:
    """
    Return the epoch during which validator activations and exits initiated in ``epoch`` take effect.
    """
    return Epoch(epoch + 1 + ACTIVATION_EXIT_DELAY)
*/
  syntax Int ::= computeActivationExitEpoch ( Epoch ) [function]
  rule computeActivationExitEpoch(EP) => EP +Int 1 +Int ACTIVATION_EXIT_DELAY

/*
def compute_domain(domain_type: DomainType, fork_version: Version=Version()) -> Domain:
    """
    Return the domain for the ``domain_type`` and ``fork_version``.
    """
    return Domain(domain_type + fork_version)
*/
// TODO fix compute_domain
  syntax Int ::= computeDomain(Int, Version) [function]
  rule computeDomain(Domain_Type, Fork_Version) => Domain_Type +Int Fork_Version

  // Helper functions -- Beacon state accessors
  //====================================================

/*
def get_current_epoch(state: BeaconState) -> Epoch:
    """
    Return the current epoch.
    """
    return compute_epoch_of_slot(state.slot)
*/
  syntax Epoch ::= getCurrentEpoch() [function]
  rule [[ getCurrentEpoch() => computeEpochOfSlot(SLOT) ]]
    <slot> SLOT </slot>

/*
def get_previous_epoch(state: BeaconState) -> Epoch:
    """`
    Return the previous epoch (unless the current epoch is ``GENESIS_EPOCH``).
    """
    current_epoch = get_current_epoch(state)
    return GENESIS_EPOCH if current_epoch == GENESIS_EPOCH else Epoch(current_epoch - 1)
*/
  syntax Epoch ::= getPreviousEpoch() [function]
  rule getPreviousEpoch() =>  #if getCurrentEpoch() ==K GENESIS_EPOCH
                                #then GENESIS_EPOCH
                                #else {getCurrentEpoch()}:>Int -Int 1
                              #fi

/*
def get_block_root(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the block root at the start of a recent ``epoch``.
    """
    return get_block_root_at_slot(state, compute_start_slot_of_epoch(epoch))
*/
// 

/*
def get_block_root_at_slot(state: BeaconState, slot: Slot) -> Hash:
    """
    Return the block root at a recent ``slot``.
    """
    assert slot < state.slot <= slot + SLOTS_PER_HISTORICAL_ROOT
    return state.block_roots[slot % SLOTS_PER_HISTORICAL_ROOT]
*/
// 

/*
def get_randao_mix(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the randao mix at a recent ``epoch``.
    """
    return state.randao_mixes[epoch % EPOCHS_PER_HISTORICAL_VECTOR]
get_active_validator_indices
*/
// 

/*
def get_active_validator_indices(state: BeaconState, epoch: Epoch) -> Sequence[ValidatorIndex]:
    """
    Return the sequence of active validator indices at ``epoch``.
    """
    return [ValidatorIndex(i) for i, v in enumerate(state.validators) if is_active_validator(v, epoch)]
*/
  syntax IntList ::= getActiveValidatorIndices( Epoch ) [function]
  rule [[ getActiveValidatorIndices(EP) => getActiveValidatorIndicesAux(.IntList, 0, VALIDATORS, EP) ]]
    <validators> VALIDATORS </validators>

  syntax IntList ::= getActiveValidatorIndicesAux( IntList, Int, Map, Epoch ) [function]
  rule getActiveValidatorIndicesAux(_,          I => I +Int 1, _:Map (I |-> V => .Map), EP )
    requires notBool isActiveValidator(V, EP)
  rule getActiveValidatorIndicesAux(Is => Is I, I => I +Int 1, _:Map (I |-> V => .Map), EP )
    requires         isActiveValidator(V, EP)
  rule getActiveValidatorIndicesAux(Is, _, .Map, _) => Is

/*
def get_validator_churn_limit(state: BeaconState) -> uint64:
    """
    Return the validator churn limit for the current epoch.
    """
    active_validator_indices = get_active_validator_indices(state, get_current_epoch(state))
    return max(MIN_PER_EPOCH_CHURN_LIMIT, len(active_validator_indices) // CHURN_LIMIT_QUOTIENT)
*/
// TODO fix get_validator_churn_limit
  syntax Int ::= getValidatorChurnLimit( ) [function]
  rule getValidatorChurnLimit() => maxInt(
          MIN_PER_EPOCH_CHURN_LIMIT,
          len(getActiveValidatorIndices(getCurrentEpoch())) /Int CHURN_LIMIT_QUOTIENT )

/*
def get_seed(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the seed at ``epoch``.
    """
    mix = get_randao_mix(state, Epoch(epoch + EPOCHS_PER_HISTORICAL_VECTOR - MIN_SEED_LOOKAHEAD))  # Avoid underflow
    active_index_root = state.active_index_roots[epoch % EPOCHS_PER_HISTORICAL_VECTOR]
    return hash(mix + active_index_root + int_to_bytes(epoch, length=32))
*/
  syntax Bytes32 ::= getSeed( Epoch ) [function]
  rule getSeed(_) => 0 //NOTEH mock implementation for now

/*
def get_committee_count(state: BeaconState, epoch: Epoch) -> uint64:
    """
    Return the number of committees at ``epoch``.
    """
    committees_per_slot = max(1, min(
        SHARD_COUNT // SLOTS_PER_EPOCH,
        len(get_active_validator_indices(state, epoch)) // SLOTS_PER_EPOCH // TARGET_COMMITTEE_SIZE,
    ))
    return committees_per_slot * SLOTS_PER_EPOCH
*/
  syntax Int ::= getCommitteeCount( Epoch ) [function]
  rule getCommitteeCount( EP )
    => maxInt(1, minInt(SHARD_COUNT /Int SLOTS_PER_EPOCH,
                        len(getActiveValidatorIndices(EP)) /Int SLOTS_PER_EPOCH /Int TARGET_COMMITTEE_SIZE
                 )
             ) *Int SLOTS_PER_EPOCH

/*
def get_crosslink_committee(state: BeaconState, epoch: Epoch, shard: Shard) -> Sequence[ValidatorIndex]:
    """
    Return the crosslink committee at ``epoch`` for ``shard``.
    """
    return compute_committee(
        indices=get_active_validator_indices(state, epoch),
        seed=get_seed(state, epoch),
        index=(shard + SHARD_COUNT - get_start_shard(state, epoch)) % SHARD_COUNT,
        count=get_committee_count(state, epoch),
    )
*/
  syntax IntList ::= getCrosslinkCommittee( Epoch, Shard ) [function]
  rule getCrosslinkCommittee(EPOCH, SHARD)
    => computeCommittee(
          getActiveValidatorIndices(EPOCH),
          getSeed(EPOCH),
          (SHARD +Int SHARD_COUNT -Int {getStartShard(EPOCH)}:>Int) %Int SHARD_COUNT,
          getCommitteeCount(EPOCH)
    )

/*
def get_start_shard(state: BeaconState, epoch: Epoch) -> Shard:
    """
    Return the start shard of the 0th committee at ``epoch``.
    """
    assert epoch <= get_current_epoch(state) + 1
    check_epoch = Epoch(get_current_epoch(state) + 1)
    shard = Shard((state.start_shard + get_shard_delta(state, get_current_epoch(state))) % SHARD_COUNT)
    while check_epoch > epoch:
        check_epoch -= Epoch(1)
        shard = Shard((shard + SHARD_COUNT - get_shard_delta(state, check_epoch)) % SHARD_COUNT)
    return shard
*/
  syntax Shard ::= getStartShard( Epoch ) [function]
  rule [[ getStartShard(EPOCH) => getStartShardAux(
      {{getCurrentEpoch()}:>Int +Int 1}:>Epoch,
      (LSS +Int getShardDelta(getCurrentEpoch())) %Int SHARD_COUNT,
      EPOCH
    ) ]]
    <latest-start-shard> LSS </latest-start-shard>
    requires EPOCH <=Int {getCurrentEpoch()}:>Int +Int 1

  syntax Shard ::= getStartShardAux( Epoch, Shard, Epoch ) [function]
  rule getStartShardAux(
      CheckEP => CheckEP -Int 1,
      SHARD => SHARD +Int SHARD_COUNT -Int getShardDelta(CheckEP -Int 1) %Int SHARD_COUNT,
      EPOCH
    )
    requires CheckEP >Int EPOCH

  rule getStartShardAux(CheckEP, SHARD, EPOCH) => SHARD
    requires CheckEP <=Int EPOCH

/*
def get_shard_delta(state: BeaconState, epoch: Epoch) -> uint64:
    """
    Return the number of shards to increment ``state.start_shard`` at ``epoch``.
    """
    return min(get_committee_count(state, epoch), SHARD_COUNT - SHARD_COUNT // SLOTS_PER_EPOCH)
*/
  syntax Int ::= getShardDelta( Epoch ) [function]
  rule getShardDelta( EPOCH ) => minInt(
    getCommitteeCount(EPOCH),
    SHARD_COUNT -Int SHARD_COUNT /Int SLOTS_PER_EPOCH
  )

/*
def get_beacon_proposer_index(state: BeaconState) -> ValidatorIndex:
    """
    Return the beacon proposer index at the current slot.
    """
    epoch = get_current_epoch(state)
    committees_per_slot = get_committee_count(state, epoch) // SLOTS_PER_EPOCH
    offset = committees_per_slot * (state.slot % SLOTS_PER_EPOCH)
    shard = Shard((get_start_shard(state, epoch) + offset) % SHARD_COUNT)
    first_committee = get_crosslink_committee(state, epoch, shard)
    MAX_RANDOM_BYTE = 2**8 - 1
    seed = get_seed(state, epoch)
    i = 0
    while True:
        candidate_index = first_committee[(epoch + i) % len(first_committee)]
        random_byte = hash(seed + int_to_bytes(i // 32, length=8))[i % 32]
        effective_balance = state.validators[candidate_index].effective_balance
        if effective_balance * MAX_RANDOM_BYTE >= MAX_EFFECTIVE_BALANCE * random_byte:
            return ValidatorIndex(candidate_index)
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
          //)(0/*getSeed(EPOCH)*/)
          //)(2 ^Int 8 -Int 1)
          //)(getCrosslinkCommittee(EPOCH, SHARD))
          //)({({getStartShard(EPOCH)}:>Int +Int OFFSET) %Int SHARD_COUNT}:>Shard)
          //)(CommitteesPerSlot *Int (SLOT %Int SLOTS_PER_EPOCH))
          //)(getCommitteeCount(EPOCH))
          //)(getCurrentEpoch())
       ]]
    <slot> SLOT </slot>

  syntax ValidatorIndex ::= getBeaconProposerIndexLoop(
                              Epoch, Int, Int, Shard, IntList, Int, Bytes32, Int) [function]
  rule [[ getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I)
    =>    getBeaconProposerIndexLoopAux(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I,
                  get(FirstCommittee, (EPOCH +Int I) %Int len(FirstCommittee)) #as CandidateIndex,
                  getByte( hash( toBytes({SEED}:>Int +Int I /Int 32) ), I %Int 32) /*#as RandomByte*/,
                  EffectiveBalance
          ) ]]
    <validators>... CandidateIndex |-> #Validator(_,_,_,_,_,_,_, EffectiveBalance) ...</validators>

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

/*
def get_attestation_data_slot(state: BeaconState, data: AttestationData) -> Slot:
    """
    Return the slot corresponding to the attestation ``data``.
    """
    committee_count = get_committee_count(state, data.target.epoch)
    offset = (data.crosslink.shard + SHARD_COUNT - get_start_shard(state, data.target.epoch)) % SHARD_COUNT
    return Slot(compute_start_slot_of_epoch(data.target.epoch) + offset // (committee_count // SLOTS_PER_EPOCH))
*/
// 

/*
def get_compact_committees_root(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the compact committee root at ``epoch``.
    """
    committees = [CompactCommittee() for _ in range(SHARD_COUNT)]
    start_shard = get_start_shard(state, epoch)
    for committee_number in range(get_committee_count(state, epoch)):
        shard = Shard((start_shard + committee_number) % SHARD_COUNT)
        for index in get_crosslink_committee(state, epoch, shard):
            validator = state.validators[index]
            committees[shard].pubkeys.append(validator.pubkey)
            compact_balance = validator.effective_balance // EFFECTIVE_BALANCE_INCREMENT
            # `index` (top 6 bytes) + `slashed` (16th bit) + `compact_balance` (bottom 15 bits)
            compact_validator = uint64((index << 16) + (validator.slashed << 15) + compact_balance)
            committees[shard].compact_validators.append(compact_validator)
    return hash_tree_root(Vector[CompactCommittee, SHARD_COUNT](committees))
*/
// 

/*
def get_total_balance(state: BeaconState, indices: Set[ValidatorIndex]) -> Gwei:
    """
    Return the combined effective balance of the ``indices``. (1 Gwei minimum to avoid divisions by zero.)
    """
    return Gwei(max(sum([state.validators[index].effective_balance for index in indices]), 1))
*/
  syntax Gwei ::= getTotalBalance( IntList ) [function]
  rule getTotalBalance(INDICES) => maxInt(getTotalBalancePure(INDICES, 0), 1)

  syntax Int ::= getTotalBalancePure( IntList, Int ) [function]
  rule [[ getTotalBalancePure(I IL => IL, S => S +Int EffBalance) ]]
    <validators>... I |-> #Validator(_,_,_,_,_,_,_, EffBalance) ...</validators>
  rule getTotalBalancePure(.IntList, S) => S

/*
def get_total_active_balance(state: BeaconState) -> Gwei:
    """
    Return the combined effective balance of the active validators.
    """
    return get_total_balance(state, set(get_active_validator_indices(state, get_current_epoch(state))))
*/
  syntax Gwei ::= getTotalActiveBalance() [function]
  rule getTotalActiveBalance() => getTotalBalance(getActiveValidatorIndices(getCurrentEpoch()))

/*
def get_domain(state: BeaconState, domain_type: DomainType, message_epoch: Epoch=None) -> Domain:
    """
    Return the signature domain (fork version concatenated with domain type) of a message.
    """
    epoch = get_current_epoch(state) if message_epoch is None else message_epoch
    fork_version = state.fork.previous_version if epoch < state.fork.epoch else state.fork.current_version
    return compute_domain(domain_type, fork_version)
*/
// 

/*
def get_indexed_attestation(state: BeaconState, attestation: Attestation) -> IndexedAttestation:
    """
    Return the indexed attestation corresponding to ``attestation``.
    """
    attesting_indices = get_attesting_indices(state, attestation.data, attestation.aggregation_bits)
    custody_bit_1_indices = get_attesting_indices(state, attestation.data, attestation.custody_bits)
    assert custody_bit_1_indices.issubset(attesting_indices)
    custody_bit_0_indices = attesting_indices.difference(custody_bit_1_indices)

    return IndexedAttestation(
        custody_bit_0_indices=sorted(custody_bit_0_indices),
        custody_bit_1_indices=sorted(custody_bit_1_indices),
        data=attestation.data,
        signature=attestation.signature,
    )
*/
// 

/*
def get_attesting_indices(state: BeaconState,
                          data: AttestationData,
                          bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]) -> Set[ValidatorIndex]:
    """
    Return the set of attesting indices corresponding to ``data`` and ``bits``.
    """
    committee = get_crosslink_committee(state, data.target.epoch, data.crosslink.shard)
    return set(index for i, index in enumerate(committee) if bits[i])
*/
// 

  // Helper functions -- Beacon state mutators
  //====================================================

/*
def increase_balance(state: BeaconState, index: ValidatorIndex, delta: Gwei) -> None:
    """
    Increase the validator balance at index ``index`` by ``delta``.
    """
    state.balances[index] += delta
*/
  syntax KItem ::= "increaseBalance" "(" ValidatorIndex "," Gwei ")"
  rule <k> increaseBalance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => BAL +Int Delta) ...</balances>

/*
def decrease_balance(state: BeaconState, index: ValidatorIndex, delta: Gwei) -> None:
    """
    Decrease the validator balance at index ``index`` by ``delta``, with underflow protection.
    """
    state.balances[index] = 0 if delta > state.balances[index] else state.balances[index] - delta
*/
  syntax KItem ::= "decreaseBalance" "(" ValidatorIndex "," Gwei ")"
  rule <k> decreaseBalance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => #if Delta >Int BAL #then 0 #else BAL -Int Delta #fi) ...</balances>


/*
def initiate_validator_exit(state: BeaconState, index: ValidatorIndex) -> None:
    """
    Initiate the exit of the validator with index ``index``.
    """
    # Return if validator already initiated exit
    validator = state.validators[index]
    if validator.exit_epoch != FAR_FUTURE_EPOCH:
        return

    # Compute exit queue epoch
    exit_epochs = [v.exit_epoch for v in state.validators if v.exit_epoch != FAR_FUTURE_EPOCH]
    exit_queue_epoch = max(exit_epochs + [compute_activation_exit_epoch(get_current_epoch(state))])
    exit_queue_churn = len([v for v in state.validators if v.exit_epoch == exit_queue_epoch])
    if exit_queue_churn >= get_validator_churn_limit(state):
        exit_queue_epoch += Epoch(1)

    # Set validator exit epoch and withdrawable epoch
    validator.exit_epoch = exit_queue_epoch
    validator.withdrawable_epoch = Epoch(validator.exit_epoch + MIN_VALIDATOR_WITHDRAWABILITY_DELAY)
*/
  syntax KItem ::= initiateValidatorExit( Int )
                 | initiateValidatorExitAux( Int /*index*/ , Epoch /*exit_queue_epoch*/ )

  rule <k> initiateValidatorExit(INDEX) => .K ...</k>
       <validators>... INDEX |-> #Validator(_,_,_,_, ExitEPOCH, _,_,_) ...</validators>
    when ExitEPOCH =/=K FAR_FUTURE_EPOCH

  rule <k> initiateValidatorExit(INDEX) => initiateValidatorExitAux(INDEX, exitQueueEpochAux(INDEX)) ...</k>
       <validators>... INDEX |-> #Validator(_,_,_,_, ExitEPOCH, _,_,_) ...</validators>

  rule <k> initiateValidatorExitAux(INDEX, ExitQEpoch) => .K ...</k>
       <validators>
          (INDEX |-> #Validator(_,_,_,_,
            ExitEPOCH => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int getValidatorChurnLimit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi ,
            WithdrEpoch => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int getValidatorChurnLimit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi +Int MIN_VALIDATOR_WITHDRAWABILITY_DELAY ,
           _,_) _) #as VALIDATORS
       </validators>

  syntax Epoch ::= exitQueueEpochAux ( Int ) [function]
  rule [[ exitQueueEpochAux(INDEX)
          => maxAux({computeActivationExitEpoch(getCurrentEpoch())}:>Int
                    exitEpochsAux(VALIDATORS, .IntList) ) ]]
    <validators> VALIDATORS </validators>

  syntax IntList ::= exitEpochsAux( Map /*validators*/ , IntList /*result*/ )
  rule exitEpochsAux(_:Map (_ |-> #Validator(_,_,_,_,_,_, ExitEPOCH, _) => .Map),
                     RES => ExitEPOCH RES )
    requires ExitEPOCH =/=K FAR_FUTURE_EPOCH

  rule exitEpochsAux(_:Map (_ |-> #Validator(_,_,_,_,_,_, ExitEPOCH, _) => .Map),
                     RES /*unchanged*/ )
    requires ExitEPOCH ==K FAR_FUTURE_EPOCH

  rule exitEpochsAux(.Map, RES) => RES

  // exit_queue_churn = len([v for v in state.validator_registry if v.exit_epoch == exit_queue_epoch])
  syntax Int ::= exitQueueChurnAux ( Epoch /*exit_queue_epoch*/ , Map /*validator_registry*/ , Int /*result*/ ) [function]
  rule exitQueueChurnAux( ExitQEpoch, _:Map (_ |-> #Validator(_,_,_,_, ExitQEpoch, _,_,_) => .Map), RES => RES +Int 1 )
  rule exitQueueChurnAux( ExitQEpoch, _:Map (_ |-> #Validator(_,_,_,_, ExitEP, _,_,_) => .Map), _ )
    requires ExitEP =/=K ExitQEpoch
  rule exitQueueChurnAux( _, .Map, RES ) => RES

/*
def slash_validator(state: BeaconState,
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
//

  // Genesis state
  //====================================================

/*
def initialize_beacon_state_from_eth1(eth1_block_hash: Hash,
                                      eth1_timestamp: uint64,
                                      deposits: Sequence[Deposit]) -> BeaconState:
    state = BeaconState(
        genesis_time=eth1_timestamp - eth1_timestamp % SECONDS_PER_DAY + 2 * SECONDS_PER_DAY,
        eth1_data=Eth1Data(block_hash=eth1_block_hash, deposit_count=len(deposits)),
        latest_block_header=BeaconBlockHeader(body_root=hash_tree_root(BeaconBlockBody())),
    )

    # Process deposits
    leaves = list(map(lambda deposit: deposit.data, deposits))
    for index, deposit in enumerate(deposits):
        deposit_data_list = List[DepositData, 2**DEPOSIT_CONTRACT_TREE_DEPTH](*leaves[:index + 1])
        state.eth1_data.deposit_root = hash_tree_root(deposit_data_list)
        process_deposit(state, deposit)

    # Process activations
    for index, validator in enumerate(state.validators):
        balance = state.balances[index]
        validator.effective_balance = min(balance - balance % EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE)
        if validator.effective_balance == MAX_EFFECTIVE_BALANCE:
            validator.activation_eligibility_epoch = GENESIS_EPOCH
            validator.activation_epoch = GENESIS_EPOCH

    # Populate active_index_roots and compact_committees_roots
    indices_list = List[ValidatorIndex, VALIDATOR_REGISTRY_LIMIT](get_active_validator_indices(state, GENESIS_EPOCH))
    active_index_root = hash_tree_root(indices_list)
    committee_root = get_compact_committees_root(state, GENESIS_EPOCH)
    for index in range(EPOCHS_PER_HISTORICAL_VECTOR):
        state.active_index_roots[index] = active_index_root
        state.compact_committees_roots[index] = committee_root
    return state
*/
//

/*
def is_valid_genesis_state(state: BeaconState) -> bool:
    if state.genesis_time < MIN_GENESIS_TIME:
        return False
    if len(get_active_validator_indices(state, GENESIS_EPOCH)) < MIN_GENESIS_ACTIVE_VALIDATOR_COUNT:
        return False
    return True
*/
//


  // Beacon chain state transition function
  //====================================================

/*
def state_transition(state: BeaconState, block: BeaconBlock, validate_state_root: bool=False) -> BeaconState:
    # Process slots (including those with no blocks) since block
    process_slots(state, block.slot)
    # Process block
    process_block(state, block)
    # Validate state root (`validate_state_root == True` in production)
    if validate_state_root:
        assert block.state_root == hash_tree_root(state)
    # Return post-state
    return state
*/
//

/*
def process_slots(state: BeaconState, slot: Slot) -> None:
    assert state.slot <= slot
    while state.slot < slot:
        process_slot(state)
        # Process epoch on the start slot of the next epoch
        if (state.slot + 1) % SLOTS_PER_EPOCH == 0:
            process_epoch(state)
        state.slot += Slot(1)
*/
//

/*
def process_slot(state: BeaconState) -> None:
    # Cache state root
    previous_state_root = hash_tree_root(state)
    state.state_roots[state.slot % SLOTS_PER_HISTORICAL_ROOT] = previous_state_root
    # Cache latest block header state root
    if state.latest_block_header.state_root == Hash():
        state.latest_block_header.state_root = previous_state_root
    # Cache block root
    previous_block_root = signing_root(state.latest_block_header)
    state.block_roots[state.slot % SLOTS_PER_HISTORICAL_ROOT] = previous_block_root
*/
//

  // State transition function -- Epoch processing
  //====================================================
/*
def process_epoch(state: BeaconState) -> None:
    process_justification_and_finalization(state)
    process_crosslinks(state)
    process_rewards_and_penalties(state)
    process_registry_updates(state)
    # @process_reveal_deadlines
    # @process_challenge_deadlines
    process_slashings(state)
    process_final_updates(state)
    # @after_process_final_updates
*/
//

/*
def get_matching_source_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    assert epoch in (get_previous_epoch(state), get_current_epoch(state))
    return state.current_epoch_attestations if epoch == get_current_epoch(state) else state.previous_epoch_attestations
*/
//

/*
def get_matching_target_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    return [
        a for a in get_matching_source_attestations(state, epoch)
        if a.data.target.root == get_block_root(state, epoch)
    ]
*/
//

/*
def get_matching_head_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    return [
        a for a in get_matching_source_attestations(state, epoch)
        if a.data.beacon_block_root == get_block_root_at_slot(state, get_attestation_data_slot(state, a.data))
    ]
*/
//

/*
def get_unslashed_attesting_indices(state: BeaconState,
                                    attestations: Sequence[PendingAttestation]) -> Set[ValidatorIndex]:
    output = set()  # type: Set[ValidatorIndex]
    for a in attestations:
        output = output.union(get_attesting_indices(state, a.data, a.aggregation_bits))
    return set(filter(lambda index: not state.validators[index].slashed, list(output)))
*/
//

/*
def get_attesting_balance(state: BeaconState, attestations: Sequence[PendingAttestation]) -> Gwei:
    return get_total_balance(state, get_unslashed_attesting_indices(state, attestations))
*/
//

/*
def get_winning_crosslink_and_attesting_indices(state: BeaconState,
                                                epoch: Epoch,
                                                shard: Shard) -> Tuple[Crosslink, Set[ValidatorIndex]]:
    attestations = [a for a in get_matching_source_attestations(state, epoch) if a.data.crosslink.shard == shard]
    crosslinks = list(filter(
        lambda c: hash_tree_root(state.current_crosslinks[shard]) in (c.parent_root, hash_tree_root(c)),
        [a.data.crosslink for a in attestations]
    ))
    # Winning crosslink has the crosslink data root with the most balance voting for it (ties broken lexicographically)
    winning_crosslink = max(crosslinks, key=lambda c: (
        get_attesting_balance(state, [a for a in attestations if a.data.crosslink == c]), c.data_root
    ), default=Crosslink())
    winning_attestations = [a for a in attestations if a.data.crosslink == winning_crosslink]
    return winning_crosslink, get_unslashed_attesting_indices(state, winning_attestations)
*/
//

/*
def process_justification_and_finalization(state: BeaconState) -> None:
    if get_current_epoch(state) <= GENESIS_EPOCH + 1:
        return

    previous_epoch = get_previous_epoch(state)
    current_epoch = get_current_epoch(state)
    old_previous_justified_checkpoint = state.previous_justified_checkpoint
    old_current_justified_checkpoint = state.current_justified_checkpoint

    # Process justifications
    state.previous_justified_checkpoint = state.current_justified_checkpoint
    state.justification_bits[1:] = state.justification_bits[:-1]
    state.justification_bits[0] = 0b0
    matching_target_attestations = get_matching_target_attestations(state, previous_epoch)  # Previous epoch
    if get_attesting_balance(state, matching_target_attestations) * 3 >= get_total_active_balance(state) * 2:
        state.current_justified_checkpoint = Checkpoint(epoch=previous_epoch,
                                                        root=get_block_root(state, previous_epoch))
        state.justification_bits[1] = 0b1
    matching_target_attestations = get_matching_target_attestations(state, current_epoch)  # Current epoch
    if get_attesting_balance(state, matching_target_attestations) * 3 >= get_total_active_balance(state) * 2:
        state.current_justified_checkpoint = Checkpoint(epoch=current_epoch,
                                                        root=get_block_root(state, current_epoch))
        state.justification_bits[0] = 0b1

    # Process finalizations
    bits = state.justification_bits
    # The 2nd/3rd/4th most recent epochs are justified, the 2nd using the 4th as source
    if all(bits[1:4]) and old_previous_justified_checkpoint.epoch + 3 == current_epoch:
        state.finalized_checkpoint = old_previous_justified_checkpoint
    # The 2nd/3rd most recent epochs are justified, the 2nd using the 3rd as source
    if all(bits[1:3]) and old_previous_justified_checkpoint.epoch + 2 == current_epoch:
        state.finalized_checkpoint = old_previous_justified_checkpoint
    # The 1st/2nd/3rd most recent epochs are justified, the 1st using the 3rd as source
    if all(bits[0:3]) and old_current_justified_checkpoint.epoch + 2 == current_epoch:
        state.finalized_checkpoint = old_current_justified_checkpoint
    # The 1st/2nd most recent epochs are justified, the 1st using the 2nd as source
    if all(bits[0:2]) and old_current_justified_checkpoint.epoch + 1 == current_epoch:
        state.finalized_checkpoint = old_current_justified_checkpoint
*/
//

/*
def process_crosslinks(state: BeaconState) -> None:
    state.previous_crosslinks = [c for c in state.current_crosslinks]
    for epoch in (get_previous_epoch(state), get_current_epoch(state)):
        for offset in range(get_committee_count(state, epoch)):
            shard = Shard((get_start_shard(state, epoch) + offset) % SHARD_COUNT)
            crosslink_committee = set(get_crosslink_committee(state, epoch, shard))
            winning_crosslink, attesting_indices = get_winning_crosslink_and_attesting_indices(state, epoch, shard)
            if 3 * get_total_balance(state, attesting_indices) >= 2 * get_total_balance(state, crosslink_committee):
                state.current_crosslinks[shard] = winning_crosslink
*/
//

/*
def get_base_reward(state: BeaconState, index: ValidatorIndex) -> Gwei:
    total_balance = get_total_active_balance(state)
    effective_balance = state.validators[index].effective_balance
    return Gwei(effective_balance * BASE_REWARD_FACTOR // integer_squareroot(total_balance) // BASE_REWARDS_PER_EPOCH)
*/
  syntax Gwei ::= getBaseReward( Int ) [function]
  rule [[ getBaseReward(INDEX)
          => EffectiveBalance *Int BASE_REWARD_FACTOR
             /Int integerSquareroot({getTotalActiveBalance()}:>Int)
             /Int BASE_REWARDS_PER_EPOCH ]]
    <validators> INDEX |-> #Validator(_,_,_,_,_,_,_, EffectiveBalance) </validators>

/*
def get_attestation_deltas(state: BeaconState) -> Tuple[Sequence[Gwei], Sequence[Gwei]]:
    previous_epoch = get_previous_epoch(state)
    total_balance = get_total_active_balance(state)
    rewards = [Gwei(0) for _ in range(len(state.validators))]
    penalties = [Gwei(0) for _ in range(len(state.validators))]
    eligible_validator_indices = [
        ValidatorIndex(index) for index, v in enumerate(state.validators)
        if is_active_validator(v, previous_epoch) or (v.slashed and previous_epoch + 1 < v.withdrawable_epoch)
    ]

    # Micro-incentives for matching FFG source, FFG target, and head
    matching_source_attestations = get_matching_source_attestations(state, previous_epoch)
    matching_target_attestations = get_matching_target_attestations(state, previous_epoch)
    matching_head_attestations = get_matching_head_attestations(state, previous_epoch)
    for attestations in (matching_source_attestations, matching_target_attestations, matching_head_attestations):
        unslashed_attesting_indices = get_unslashed_attesting_indices(state, attestations)
        attesting_balance = get_total_balance(state, unslashed_attesting_indices)
        for index in eligible_validator_indices:
            if index in unslashed_attesting_indices:
                rewards[index] += get_base_reward(state, index) * attesting_balance // total_balance
            else:
                penalties[index] += get_base_reward(state, index)

    # Proposer and inclusion delay micro-rewards
    for index in get_unslashed_attesting_indices(state, matching_source_attestations):
        attestation = min([
            a for a in matching_source_attestations
            if index in get_attesting_indices(state, a.data, a.aggregation_bits)
        ], key=lambda a: a.inclusion_delay)
        proposer_reward = Gwei(get_base_reward(state, index) // PROPOSER_REWARD_QUOTIENT)
        rewards[attestation.proposer_index] += proposer_reward
        max_attester_reward = get_base_reward(state, index) - proposer_reward
        rewards[index] += Gwei(
            max_attester_reward
            * (SLOTS_PER_EPOCH + MIN_ATTESTATION_INCLUSION_DELAY - attestation.inclusion_delay)
            // SLOTS_PER_EPOCH
        )

    # Inactivity penalty
    finality_delay = previous_epoch - state.finalized_checkpoint.epoch
    if finality_delay > MIN_EPOCHS_TO_INACTIVITY_PENALTY:
        matching_target_attesting_indices = get_unslashed_attesting_indices(state, matching_target_attestations)
        for index in eligible_validator_indices:
            penalties[index] += Gwei(BASE_REWARDS_PER_EPOCH * get_base_reward(state, index))
            if index not in matching_target_attesting_indices:
                penalties[index] += Gwei(
                    state.validators[index].effective_balance * finality_delay // INACTIVITY_PENALTY_QUOTIENT
                )

    return rewards, penalties
*/
//

/*
def get_crosslink_deltas(state: BeaconState) -> Tuple[Sequence[Gwei], Sequence[Gwei]]:
    rewards = [Gwei(0) for _ in range(len(state.validators))]
    penalties = [Gwei(0) for _ in range(len(state.validators))]
    epoch = get_previous_epoch(state)
    for offset in range(get_committee_count(state, epoch)):
        shard = Shard((get_start_shard(state, epoch) + offset) % SHARD_COUNT)
        crosslink_committee = set(get_crosslink_committee(state, epoch, shard))
        winning_crosslink, attesting_indices = get_winning_crosslink_and_attesting_indices(state, epoch, shard)
        attesting_balance = get_total_balance(state, attesting_indices)
        committee_balance = get_total_balance(state, crosslink_committee)
        for index in crosslink_committee:
            base_reward = get_base_reward(state, index)
            if index in attesting_indices:
                rewards[index] += base_reward * attesting_balance // committee_balance
            else:
                penalties[index] += base_reward
    return rewards, penalties
*/
//

/*
def process_rewards_and_penalties(state: BeaconState) -> None:
    if get_current_epoch(state) == GENESIS_EPOCH:
        return

    rewards1, penalties1 = get_attestation_deltas(state)
    rewards2, penalties2 = get_crosslink_deltas(state)
    for index in range(len(state.validators)):
        increase_balance(state, ValidatorIndex(index), rewards1[index] + rewards2[index])
        decrease_balance(state, ValidatorIndex(index), penalties1[index] + penalties2[index])
*/
//

/*
def process_registry_updates(state: BeaconState) -> None:
    # Process activation eligibility and ejections
    for index, validator in enumerate(state.validators):
        if (
            validator.activation_eligibility_epoch == FAR_FUTURE_EPOCH
            and validator.effective_balance == MAX_EFFECTIVE_BALANCE
        ):
            validator.activation_eligibility_epoch = get_current_epoch(state)

        if is_active_validator(validator, get_current_epoch(state)) and validator.effective_balance <= EJECTION_BALANCE:
            initiate_validator_exit(state, ValidatorIndex(index))

    # Queue validators eligible for activation and not dequeued for activation prior to finalized epoch
    activation_queue = sorted([
        index for index, validator in enumerate(state.validators)
        if validator.activation_eligibility_epoch != FAR_FUTURE_EPOCH
        and validator.activation_epoch >= compute_activation_exit_epoch(state.finalized_checkpoint.epoch)
    ], key=lambda index: state.validators[index].activation_eligibility_epoch)
    # Dequeued validators for activation up to churn limit (without resetting activation epoch)
    for index in activation_queue[:get_validator_churn_limit(state)]:
        validator = state.validators[index]
        if validator.activation_epoch == FAR_FUTURE_EPOCH:
            validator.activation_epoch = compute_activation_exit_epoch(get_current_epoch(state))
*/
  syntax KItem ::= "processRegistryUpdates"
  rule <k> processRegistryUpdates
           => processRegistryUpdatesLoop1(VALIDATORS)
           ~> processActivationQueue()
         ...
       </k>
       <validators> VALIDATORS </validators>

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
       <validators>... INDEX |-> #Validator(_,_, EffBalance, _,
          ActEligibilityEpoch
          => #if ActEligibilityEpoch ==Int FAR_FUTURE_EPOCH
                 andBool EffBalance >=Int MAX_EFFECTIVE_BALANCE
                #then getCurrentEpoch()
                #else ActEligibilityEpoch
             #fi,
          _,_,_) ...</validators>

  rule processRegistryUpdatesLoop1(.Map) => .K

  syntax KItem ::= "processActivationQueue" "("")"
                 | "processActivationQueue" "(" IntList /*activation queue*/ "," Int /*churn limit*/ ")"

  //must be done here instead of main rule, basause it must state updated by Loop1
  rule <k> processActivationQueue() => processActivationQueue(
          sortActivationQueue(getActivationQueueUnsorted(VALIDATORS, .IntList)),
          getValidatorChurnLimit() )
          ...
       </k>
       <validators> VALIDATORS </validators>

  rule <k> processActivationQueue(INDEX:Int IL => IL, I => I -Int 1) ... </k>
       <validators>... INDEX |-> #Validator(_,_,_,_,_,
          ActEpoch => computeActivationExitEpoch(getCurrentEpoch()), _,_)
          ...</validators>
    requires I >Int 0
             andBool ActEpoch ==K FAR_FUTURE_EPOCH

  rule <k> processActivationQueue(INDEX:Int IL => IL, I => I -Int 1) ... </k>
       <validators>... INDEX |-> #Validator(_,_,_, ActEpoch, _,_,_,_) ...</validators>
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
         andBool ActEpoch >=Int computeActivationExitEpoch(FinalizedEpoch)

  rule [[ getActivationQueueUnsorted(_:Map (INDEX |-> #Validator(_,_, ActEligibilityEpoch, ActEpoch, _,_,_,_) => .Map),
                                     IL /*unchanged*/ ) ]]
       <finalized-epoch> FinalizedEpoch </finalized-epoch>
    when notBool ( ActEligibilityEpoch =/=K FAR_FUTURE_EPOCH
                   andBool ActEpoch >=Int computeActivationExitEpoch(FinalizedEpoch) )

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
    <validators>
      MIN |-> #Validator(_,_, MINActEligibilityEpoch, _,_,_,_,_)
      I   |-> #Validator(_,_,   IActEligibilityEpoch, _,_,_,_,_)
      ...
    </validators>
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
def process_slashings(state: BeaconState) -> None:
    epoch = get_current_epoch(state)
    total_balance = get_total_active_balance(state)
    for index, validator in enumerate(state.validators):
        if validator.slashed and epoch + EPOCHS_PER_SLASHINGS_VECTOR // 2 == validator.withdrawable_epoch:
            penalty = validator.effective_balance * min(sum(state.slashings) * 3, total_balance) // total_balance
            decrease_balance(state, ValidatorIndex(index), penalty)
*/
//

/*
def process_final_updates(state: BeaconState) -> None:
    current_epoch = get_current_epoch(state)
    next_epoch = Epoch(current_epoch + 1)
    # Reset eth1 data votes
    if (state.slot + 1) % SLOTS_PER_ETH1_VOTING_PERIOD == 0:
        state.eth1_data_votes = []
    # Update effective balances with hysteresis
    for index, validator in enumerate(state.validators):
        balance = state.balances[index]
        HALF_INCREMENT = EFFECTIVE_BALANCE_INCREMENT // 2
        if balance < validator.effective_balance or validator.effective_balance + 3 * HALF_INCREMENT < balance:
            validator.effective_balance = min(balance - balance % EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE)
    # Update start shard
    state.start_shard = Shard((state.start_shard + get_shard_delta(state, current_epoch)) % SHARD_COUNT)
    # Set active index root
    index_epoch = Epoch(next_epoch + ACTIVATION_EXIT_DELAY)
    index_root_position = index_epoch % EPOCHS_PER_HISTORICAL_VECTOR
    indices_list = List[ValidatorIndex, VALIDATOR_REGISTRY_LIMIT](get_active_validator_indices(state, index_epoch))
    state.active_index_roots[index_root_position] = hash_tree_root(indices_list)
    # Set committees root
    committee_root_position = next_epoch % EPOCHS_PER_HISTORICAL_VECTOR
    state.compact_committees_roots[committee_root_position] = get_compact_committees_root(state, next_epoch)
    # Reset slashings
    state.slashings[next_epoch % EPOCHS_PER_SLASHINGS_VECTOR] = Gwei(0)
    # Set randao mix
    state.randao_mixes[next_epoch % EPOCHS_PER_HISTORICAL_VECTOR] = get_randao_mix(state, current_epoch)
    # Set historical root accumulator
    if next_epoch % (SLOTS_PER_HISTORICAL_ROOT // SLOTS_PER_EPOCH) == 0:
        historical_batch = HistoricalBatch(block_roots=state.block_roots, state_roots=state.state_roots)
        state.historical_roots.append(hash_tree_root(historical_batch))
    # Rotate current/previous epoch attestations
    state.previous_epoch_attestations = state.current_epoch_attestations
    state.current_epoch_attestations = []
*/
//

  // State transition function -- Block processing
  //====================================================

/*
def process_block(state: BeaconState, block: BeaconBlock) -> None:
    process_block_header(state, block)
    process_randao(state, block.body)
    process_eth1_data(state, block.body)
    process_operations(state, block.body)
*/
//

/*
def process_block_header(state: BeaconState, block: BeaconBlock) -> None:
    # Verify that the slots match
    assert block.slot == state.slot
    # Verify that the parent matches
    assert block.parent_root == signing_root(state.latest_block_header)
    # Save current block as the new latest block
    state.latest_block_header = BeaconBlockHeader(
        slot=block.slot,
        parent_root=block.parent_root,
        state_root=Hash(),  # Overwritten in the next `process_slot` call
        body_root=hash_tree_root(block.body),
    )
    # Verify proposer is not slashed
    proposer = state.validators[get_beacon_proposer_index(state)]
    assert not proposer.slashed
    # Verify proposer signature
    assert bls_verify(proposer.pubkey, signing_root(block), block.signature, get_domain(state, DOMAIN_BEACON_PROPOSER))
*/
//

/*
def process_randao(state: BeaconState, body: BeaconBlockBody) -> None:
    epoch = get_current_epoch(state)
    # Verify RANDAO reveal
    proposer = state.validators[get_beacon_proposer_index(state)]
    assert bls_verify(proposer.pubkey, hash_tree_root(epoch), body.randao_reveal, get_domain(state, DOMAIN_RANDAO))
    # Mix in RANDAO reveal
    mix = xor(get_randao_mix(state, epoch), hash(body.randao_reveal))
    state.randao_mixes[epoch % EPOCHS_PER_HISTORICAL_VECTOR] = mix
*/
//

/*
def process_eth1_data(state: BeaconState, body: BeaconBlockBody) -> None:
    state.eth1_data_votes.append(body.eth1_data)
    if state.eth1_data_votes.count(body.eth1_data) * 2 > SLOTS_PER_ETH1_VOTING_PERIOD:
        state.eth1_data = body.eth1_data
*/
//

/*
def process_operations(state: BeaconState, body: BeaconBlockBody) -> None:
    # Verify that outstanding deposits are processed up to the maximum number of deposits
    assert len(body.deposits) == min(MAX_DEPOSITS, state.eth1_data.deposit_count - state.eth1_deposit_index)
    # Verify that there are no duplicate transfers
    assert len(body.transfers) == len(set(body.transfers))

    for operations, function in (
        (body.proposer_slashings, process_proposer_slashing),
        (body.attester_slashings, process_attester_slashing),
        (body.attestations, process_attestation),
        (body.deposits, process_deposit),
        (body.voluntary_exits, process_voluntary_exit),
        (body.transfers, process_transfer),
    ):
        for operation in operations:
            function(state, operation)
*/
//

/*
def process_proposer_slashing(state: BeaconState, proposer_slashing: ProposerSlashing) -> None:
    proposer = state.validators[proposer_slashing.proposer_index]
    # Verify that the epoch is the same
    assert (compute_epoch_of_slot(proposer_slashing.header_1.slot)
            == compute_epoch_of_slot(proposer_slashing.header_2.slot))
    # But the headers are different
    assert proposer_slashing.header_1 != proposer_slashing.header_2
    # Check proposer is slashable
    assert is_slashable_validator(proposer, get_current_epoch(state))
    # Signatures are valid
    for header in (proposer_slashing.header_1, proposer_slashing.header_2):
        domain = get_domain(state, DOMAIN_BEACON_PROPOSER, compute_epoch_of_slot(header.slot))
        assert bls_verify(proposer.pubkey, signing_root(header), header.signature, domain)

    slash_validator(state, proposer_slashing.proposer_index)
*/
//

/*
def process_attester_slashing(state: BeaconState, attester_slashing: AttesterSlashing) -> None:
    attestation_1 = attester_slashing.attestation_1
    attestation_2 = attester_slashing.attestation_2
    assert is_slashable_attestation_data(attestation_1.data, attestation_2.data)
    assert is_valid_indexed_attestation(state, attestation_1)
    assert is_valid_indexed_attestation(state, attestation_2)

    slashed_any = False
    attesting_indices_1 = attestation_1.custody_bit_0_indices + attestation_1.custody_bit_1_indices
    attesting_indices_2 = attestation_2.custody_bit_0_indices + attestation_2.custody_bit_1_indices
    for index in sorted(set(attesting_indices_1).intersection(attesting_indices_2)):
        if is_slashable_validator(state.validators[index], get_current_epoch(state)):
            slash_validator(state, index)
            slashed_any = True
    assert slashed_any
*/
//

/*
def process_attestation(state: BeaconState, attestation: Attestation) -> None:
    data = attestation.data
    assert data.crosslink.shard < SHARD_COUNT
    assert data.target.epoch in (get_previous_epoch(state), get_current_epoch(state))

    attestation_slot = get_attestation_data_slot(state, data)
    assert attestation_slot + MIN_ATTESTATION_INCLUSION_DELAY <= state.slot <= attestation_slot + SLOTS_PER_EPOCH

    pending_attestation = PendingAttestation(
        data=data,
        aggregation_bits=attestation.aggregation_bits,
        inclusion_delay=state.slot - attestation_slot,
        proposer_index=get_beacon_proposer_index(state),
    )

    if data.target.epoch == get_current_epoch(state):
        assert data.source == state.current_justified_checkpoint
        parent_crosslink = state.current_crosslinks[data.crosslink.shard]
        state.current_epoch_attestations.append(pending_attestation)
    else:
        assert data.source == state.previous_justified_checkpoint
        parent_crosslink = state.previous_crosslinks[data.crosslink.shard]
        state.previous_epoch_attestations.append(pending_attestation)

    # Check crosslink against expected parent crosslink
    assert data.crosslink.parent_root == hash_tree_root(parent_crosslink)
    assert data.crosslink.start_epoch == parent_crosslink.end_epoch
    assert data.crosslink.end_epoch == min(data.target.epoch, parent_crosslink.end_epoch + MAX_EPOCHS_PER_CROSSLINK)
    assert data.crosslink.data_root == Hash()  # [to be removed in phase 1]

    # Check signature
    assert is_valid_indexed_attestation(state, get_indexed_attestation(state, attestation))
*/
//

/*
def process_deposit(state: BeaconState, deposit: Deposit) -> None:
    # Verify the Merkle branch
    assert is_valid_merkle_branch(
        leaf=hash_tree_root(deposit.data),
        branch=deposit.proof,
        depth=DEPOSIT_CONTRACT_TREE_DEPTH + 1,  # Add 1 for the `List` length mix-in
        index=state.eth1_deposit_index,
        root=state.eth1_data.deposit_root,
    )

    # Deposits must be processed in order
    state.eth1_deposit_index += 1

    pubkey = deposit.data.pubkey
    amount = deposit.data.amount
    validator_pubkeys = [v.pubkey for v in state.validators]
    if pubkey not in validator_pubkeys:
        # Verify the deposit signature (proof of possession) for new validators.
        # Note: The deposit contract does not check signatures.
        # Note: Deposits are valid across forks, thus the deposit domain is retrieved directly from `compute_domain`.
        domain = compute_domain(DOMAIN_DEPOSIT)
        if not bls_verify(pubkey, signing_root(deposit.data), deposit.data.signature, domain):
            return

        # Add validator and balance entries
        state.validators.append(Validator(
            pubkey=pubkey,
            withdrawal_credentials=deposit.data.withdrawal_credentials,
            activation_eligibility_epoch=FAR_FUTURE_EPOCH,
            activation_epoch=FAR_FUTURE_EPOCH,
            exit_epoch=FAR_FUTURE_EPOCH,
            withdrawable_epoch=FAR_FUTURE_EPOCH,
            effective_balance=min(amount - amount % EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE),
        ))
        state.balances.append(amount)
    else:
        # Increase balance by deposit amount
        index = ValidatorIndex(validator_pubkeys.index(pubkey))
        increase_balance(state, index, amount)
*/
//

/*
def process_voluntary_exit(state: BeaconState, exit: VoluntaryExit) -> None:
    validator = state.validators[exit.validator_index]
    # Verify the validator is active
    assert is_active_validator(validator, get_current_epoch(state))
    # Verify the validator has not yet exited
    assert validator.exit_epoch == FAR_FUTURE_EPOCH
    # Exits must specify an epoch when they become valid; they are not valid before then
    assert get_current_epoch(state) >= exit.epoch
    # Verify the validator has been active long enough
    assert get_current_epoch(state) >= validator.activation_epoch + PERSISTENT_COMMITTEE_PERIOD
    # Verify signature
    domain = get_domain(state, DOMAIN_VOLUNTARY_EXIT, exit.epoch)
    assert bls_verify(validator.pubkey, signing_root(exit), exit.signature, domain)
    # Initiate exit
    initiate_validator_exit(state, exit.validator_index)
*/
//

/*
def process_transfer(state: BeaconState, transfer: Transfer) -> None:
    # Verify the balance the covers amount and fee (with overflow protection)
    assert state.balances[transfer.sender] >= max(transfer.amount + transfer.fee, transfer.amount, transfer.fee)
    # A transfer is valid in only one slot
    assert state.slot == transfer.slot
    # Sender must satisfy at least one of the following:
    assert (
        # 1) Never have been eligible for activation
        state.validators[transfer.sender].activation_eligibility_epoch == FAR_FUTURE_EPOCH or
        # 2) Be withdrawable
        get_current_epoch(state) >= state.validators[transfer.sender].withdrawable_epoch or
        # 3) Have a balance of at least MAX_EFFECTIVE_BALANCE after the transfer
        state.balances[transfer.sender] >= transfer.amount + transfer.fee + MAX_EFFECTIVE_BALANCE
    )
    # Verify that the pubkey is valid
    assert state.validators[transfer.sender].withdrawal_credentials == BLS_WITHDRAWAL_PREFIX + hash(transfer.pubkey)[1:]
    # Verify that the signature is valid
    assert bls_verify(transfer.pubkey, signing_root(transfer), transfer.signature, get_domain(state, DOMAIN_TRANSFER))
    # Process the transfer
    decrease_balance(state, transfer.sender, transfer.amount + transfer.fee)
    increase_balance(state, transfer.recipient, transfer.amount)
    increase_balance(state, get_beacon_proposer_index(state), transfer.fee)
    # Verify balances are not dust
    assert not (0 < state.balances[transfer.sender] < MIN_DEPOSIT_AMOUNT)
    assert not (0 < state.balances[transfer.recipient] < MIN_DEPOSIT_AMOUNT)
*/
//

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

  syntax Bytes ::= toBytes( Int ) [function]

  //first argument is a result of hash(), e.g. a 256-bit number.
  syntax Int ::= getByte(Bytes, Int) [function]
  rule getByte(BYTES, I) => Bytes2Int(substrBytes(BYTES, I, I), BE, Unsigned)
  //todo question: what endianness should we use above?

endmodule
