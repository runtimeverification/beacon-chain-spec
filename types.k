module TYPES
  imports DOMAINS

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
  syntax SSZValue ::= Int | Uint64 | Bool

  //Represents List/Vector in Python, for objects that are subject to merkelization/hashing.
  syntax Vector ::= "#V" "(" Map "," Int ")"

  //Access vector by key.
  syntax KItem ::= Vector "[" Int "]"
  rule #V((KEY |-> VAL) _:Map, _) [ KEY ] => VAL

  syntax KItem ::= Pgm
  syntax Pgm ::= ".Pgm"
  syntax Fork ::= ".Fork"
  syntax BlockHeader ::= ".BlockHeader" | BeaconBlockHeader
  syntax Eth1Data ::= ".Eth1Data"
  syntax Checkpoint ::= ".Checkpoint"

  // Custom types
  //====================================================
  syntax ValidatorIndex ::= Int | ".ValidatorIndex"     //a validator registry index
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
  rule WHISTLEBLOWER_REWARD_QUOTIENT => 2 ^Int 9              [macro]
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
  syntax Fork ::= #Fork( Version, Version, Int ) [klabel(#Fork), symbol]

  syntax Version ::= Fork "." "previousVersion"                       [function]
  rule #Fork(PV,_,_).previousVersion => PV
  syntax Version ::= Fork "." "currentVersion"                        [function]
  rule #Fork(_,CV,_).currentVersion => CV
  syntax Int ::= Fork "." "epoch"                                     [function]
  rule #Fork(_,_,EPOCH).epoch => EPOCH

  /*
class Checkpoint(Container):
    epoch: Epoch
    root: Hash
  */
  syntax Checkpoint ::= #Checkpoint( Int, Hash ) [klabel(#Checkpoint), symbol]

  syntax Int ::= Checkpoint "." "epoch"                               [function]
  rule #Checkpoint(EPOCH,_).epoch => EPOCH
  syntax Hash ::= Checkpoint "." "root"                               [function]
  rule #Checkpoint(_,ROOT).root => ROOT

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
  syntax Validator ::= #Validator( BLSPubkey, Hash, Int, Bool, Int, Int, Int, Int ) [klabel(#Validator), symbol]

  syntax BLSPubkey ::= Validator "." "pubkey"                         [function]
  rule #Validator(PK, _,_,_,_,_,_,_).pubkey => PK
  syntax Hash      ::= Validator "." "withdrawalCredentials"          [function]
  rule #Validator(_, HASH, _,_,_,_,_,_).withdrawalCredentials => HASH
  syntax Int      ::= Validator "." "effectiveBalance"                [function]
  rule #Validator(_,_, EffBal, _,_,_,_,_).effectiveBalance => EffBal
  syntax Bool      ::= Validator "." "slashed"                        [function]
  rule #Validator(_,_,_, SLASHED, _,_,_,_).slashed => SLASHED
  syntax Int       ::= Validator "." "activationEligibilityEpoch"     [function]
  rule #Validator(_,_,_,_, ActEligEpoch, _,_,_).activationEligibilityEpoch => ActEligEpoch
  syntax Int       ::= Validator "." "activationEpoch"                [function]
  rule #Validator(_,_,_,_,_, ActivationEpoch, _,_).activationEpoch => ActivationEpoch
  syntax Int       ::= Validator "." "exitEpoch"                      [function]
  rule #Validator(_,_,_,_,_,_, ExitEpoch, _).exitEpoch => ExitEpoch
  syntax Int       ::= Validator "." "withdrawableEpoch"              [function]
  rule #Validator(_,_,_,_,_,_,_, WithdrawableEpoch).withdrawableEpoch => WithdrawableEpoch

  /*
class Crosslink(Container):
    shard: Shard
    parent_root: Hash
    # Crosslinking data
    start_epoch: Epoch
    end_epoch: Epoch
    data_root: Hash
  */
  syntax Crosslink ::= #Crosslink( Int, Hash, Int, Int, Hash ) [klabel(#Crosslink), symbol]

  syntax Int ::= Crosslink "." "shard"                                [function]
  rule #Crosslink(SHARD, _,_,_,_).shard => SHARD
  syntax Hash ::= Crosslink "." "parentRoot"                          [function]
  rule #Crosslink(_,ROOT,_,_,_).parentRoot => ROOT
  syntax Int ::= Crosslink "." "startEpoch"                           [function]
  rule #Crosslink(_,_,EPOCH,_,_).startEpoch => EPOCH
  syntax Int ::= Crosslink "." "endEpoch"                             [function]
  rule #Crosslink(_,_,_,EPOCH,_).endEpoch => EPOCH
  syntax Int ::= Crosslink "." "dataRoot"                             [function]
  rule #Crosslink(_,_,_,_,ROOT).dataRoot => ROOT

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
  syntax AttestationData ::= #AttestationData( Hash, Checkpoint, Checkpoint, Crosslink ) [klabel(#AttestationData), symbol]

  syntax Hash ::= AttestationData "." "beaconBlockRoot"               [function]
  rule #AttestationData(ROOT,_,_,_).beaconBlockRoot => ROOT
  syntax Checkpoint ::= AttestationData "." "source"                  [function]
  rule #AttestationData(_,CP,_,_).source => CP
  syntax Checkpoint ::= AttestationData "." "target"                  [function]
  rule #AttestationData(_,_,CP,_).target => CP
  syntax Crosslink ::= AttestationData "." "crosslink"                [function]
  rule #AttestationData(_,_,_,CL).crosslink => CL

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
  syntax IndexedAttestation ::= #IndexedAttestation( IntList, IntList, AttestationData, BLSSignature )

  syntax IntList ::= IndexedAttestation "." "custodyBit0Indices"      [function]
  rule #IndexedAttestation( IL0, _, _, _ ).custodyBit0Indices => IL0
  syntax IntList ::= IndexedAttestation "." "custodyBit1Indices"      [function]
  rule #IndexedAttestation( _, IL1, _, _ ).custodyBit1Indices => IL1
  syntax AttestationData ::= IndexedAttestation "." "data"            [function]
  rule #IndexedAttestation( _,_, DATA, _ ).data => DATA

  /*
class PendingAttestation(Container):
    aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
    data: AttestationData
    inclusion_delay: Slot
    proposer_index: ValidatorIndex
  */
  // TODO: Add constraint on length of BitList (MAX_VALIDATORS_PER_COMMITTEE)
  syntax PendingAttestation ::= #PendingAttestation( BitList, AttestationData, Int, ValidatorIndex ) [klabel(#PendingAttestation), symbol]

  syntax BitList ::= PendingAttestation "." "aggregationBits"         [function]
  rule #PendingAttestation(BITS,_,_,_).aggregationBits => BITS
  syntax AttestationData ::= PendingAttestation "." "data"            [function]
  rule #PendingAttestation(_,DATA,_,_).data => DATA
  syntax Int ::= PendingAttestation "." "inclusionDelay"              [function]
  rule #PendingAttestation(_,_,SLOT,_).inclusionDelay => SLOT
  syntax ValidatorIndex ::= PendingAttestation "." "proposerIndex"    [function]
  rule #PendingAttestation(_,_,_,VI).proposerIndex => VI

  /*
class Eth1Data(Container):
    deposit_root: Hash
    deposit_count: uint64
    block_hash: Hash
  */
  syntax Eth1Data ::= #Eth1Data( Hash, Uint64, Hash ) [klabel(#Eth1Data), symbol]

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
  syntax DepositData ::= #DepositData( BLSPubkey, Hash, Int, BLSSignature )

  syntax BLSPubkey  ::= DepositData "." "pubkey"                      [function]
  rule #DepositData( PUBKEY, _,_,_ ).pubkey => PUBKEY
  syntax Hash       ::= DepositData "." "withdrawal_credentials"      [function]
  rule #DepositData( _, WC, _,_ ).withdrawal_credentials => WC
  syntax Int        ::= DepositData "." "amount"                      [function]
  rule #DepositData( _,_, AMOUNT, _ ).amount => AMOUNT

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
  syntax BeaconBlockHeader ::= #BeaconBlockHeader( Int, Hash, Hash, Hash, BLSSignature ) [klabel(#BeaconBlockHeader), symbol]

  //Cannot use "slot", conflicts with cell <slot>
  syntax Int  ::= BeaconBlockHeader "." "_slot"                       [function]
  rule #BeaconBlockHeader(SLOT, _,_,_,_)._slot => SLOT
  syntax Hash ::= BeaconBlockHeader "." "parent_root"                 [function]
  rule #BeaconBlockHeader(_,ParentRoot, _,_,_).parent_root => ParentRoot
  syntax Hash ::= BeaconBlockHeader "." "state_root"                  [function]
  rule #BeaconBlockHeader(_,_,StateRoot, _,_).state_root => StateRoot
  syntax Hash ::= BeaconBlockHeader "." "body_root"                   [function]
  rule #BeaconBlockHeader(_,_,_,BodyRoot, _).body_root => BodyRoot

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

  syntax BitList ::= Attestation "." "aggregation_bits"               [function]
  rule #Attestation(AggrBITS, _,_,_).aggregation_bits => AggrBITS
  syntax AttestationData ::= Attestation "." "_data"                  [function]
  rule #Attestation(_, AttDATA, _,_)._data => AttDATA


  /*
class Deposit(Container):
    proof: Vector[Hash, DEPOSIT_CONTRACT_TREE_DEPTH + 1]  # Merkle path to deposit data list root
    data: DepositData
  */
  // TODO: Add constraint on length of HashList (DEPOSIT_CONTRACT_TREE_DEPTH + 1)
  syntax Deposit ::= #Deposit( HashList, DepositData )

  syntax DepositData ::= Deposit "." "data"                           [function]
  rule #Deposit(_, DATA).data => DATA


  /*
class VoluntaryExit(Container):
    epoch: Epoch  # Earliest epoch when voluntary exit can be processed
    validator_index: ValidatorIndex
    signature: BLSSignature
  */
  syntax VoluntaryExit ::= #VoluntaryExit( Int, ValidatorIndex, BLSSignature )

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
  syntax Transfer ::= #Transfer( ValidatorIndex, ValidatorIndex, Int, Int, Int, BLSPubkey, BLSSignature )

  syntax Container ::= Fork | Checkpoint | Validator | Crosslink | AttestationData | AttestationDataAndCustodyBit
                     | IndexedAttestation | PendingAttestation | Eth1Data | HistoricalBatch | DepositData
                     | CompactCommittee | BeaconBlockHeader | AttesterSlashing | Attestation | Deposit
                     | DepositData | VoluntaryExit | Transfer

  // Type conversion functions
  //====================================================

  syntax Int ::= toInt( BitList , Int /*size*/ )                      [function]
               | toInt( BitList , Int /*size*/ , Int /*result*/ )     [function]
  rule toInt(BL, SIZE) => toInt(BL, SIZE, 1)
  rule toInt(BIT BL => BL, SIZE => SIZE -Int 1, RES => 2 *Int RES +Int BL)
    requires SIZE >Int 0
  rule toInt(.BitList, SIZE => SIZE -Int 1, RES => 2 *Int RES)
    requires SIZE >Int 0
  rule toInt(.BitList, 0, RES) => RES

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

endmodule