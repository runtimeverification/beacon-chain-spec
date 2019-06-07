module BEACON-CHAIN
  imports DOMAINS

  configuration
    <k> $TODO </k>
    <state>                           //Type BeaconState in python spec.
      <slot> 0 </slot>
      <genesis-time> 0 </genesis-time>
      <fork> .K </fork>
      <validator-registry> .ValidatorList </validator-registry>
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
      <latest-block-header> .K </latest-block-header>
      <historical-roots> .Bytes32List </historical-roots>
      <latest-eth1-data> .K </latest-eth1-data>
      <eth1-data-votes> .Eth1DataList </eth1-data-votes>
      <deposit-index> 0 </deposit-index>
    </state>
    <block>                           //Type BeaconBlock in python spec.
      <blockSlot> -1 </blockSlot>
      <parent-root> -1 </parent-root>
      <state-root> -1 </state-root>
      <body>                          //Type BeaconBlockBody in python spec.
        <randao-reveal> -1 </randao-reveal>
        <eth1-data> .K </eth1-data>
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
class AttestationDataAndCustodyBit(Container):
    # Attestation data
    data: AttestationData
    # Custody bit
    custody_bit: bool
  */
  syntax AttestationDataAndCustodyBit ::= #AttestationDataAndCustodyBit( AttestationData, Bool )

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
class Eth1Data(Container):
    # Root of the deposit tree
    deposit_root: Bytes32
    # Total number of deposits
    deposit_count: uint64
    # Block hash
    block_hash: Bytes32
  */
  syntax Eth1Data ::= #Eth1Data( Bytes32, Uint64, Bytes32 )

  /*
class HistoricalBatch(Container):
    # Block roots
    block_roots: Vector[Bytes32, SLOTS_PER_HISTORICAL_ROOT]
    # State roots
    state_roots: Vector[Bytes32, SLOTS_PER_HISTORICAL_ROOT]
  */
  syntax HistoricalBatch ::= #HistoricalBatch( Bytes32List, Bytes32List )

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
class BeaconBlockHeader(Container):
    slot: uint64
    parent_root: Bytes32
    state_root: Bytes32
    body_root: Bytes32
    signature: Bytes96
  */
  syntax BeaconBlockHeader ::= #BeaconBlockHeader( Slot, Bytes32, Bytes32, Bytes32, Bytes96 )

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
class AttesterSlashing(Container):
    # First attestation
    attestation_1: IndexedAttestation
    # Second attestation
    attestation_2: IndexedAttestation
  */
  syntax AttesterSlashing ::= #AttesterSlashing( IndexedAttestation, IndexedAttestation )

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
class Deposit(Container):
    # Branch in the deposit tree
    proof: Vector[Bytes32, DEPOSIT_CONTRACT_TREE_DEPTH]
    # Data
    data: DepositData
  */
  syntax Deposit ::= #Deposit( Bytes32List, DepositData )

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

  // Python spec utility functions
  //====================================================

  syntax Bytes32 ::= xor( Bytes32, Bytes32 ) [function]
  rule xor(A,B) => A xorInt B

  syntax Int ::= blsDomain(Int, Bytes32) [function]
  rule blsDomain(Domain_Type, Fork_Version) => Domain_Type +Int Fork_Version

  syntax Epoch ::= slotToEpoch(Slot) [function]
  rule slotToEpoch(SLOT) => SLOT /Int SLOTS_PER_EPOCH

  syntax Epoch ::= getPreviousEpoch() [function]
  rule getPreviousEpoch() =>  #if getCurrentEpoch() ==K GENESIS_EPOCH
                                #then GENESIS_EPOCH
                                #else {getCurrentEpoch()}:>Int -Int 1
                              #fi

  syntax Epoch ::= getCurrentEpoch() [function]
  rule [[ getCurrentEpoch() => slotToEpoch(SLOT) ]]
    <slot> SLOT </slot>

  syntax Slot ::= getEpochStartSlot(Epoch) [function]
  rule getEpochStartSlot(EPOCH) => EPOCH *Int SLOTS_PER_EPOCH

  syntax Bool ::= isActiveValidator( Validator, Epoch ) [function]
  rule isActiveValidator( #Validator(_,_,_, ActivationEpoch, ExitEpoch, _,_,_), EPOCH )
    => ActivationEpoch <=Int EPOCH andBool EPOCH <Int ExitEpoch

  syntax Bool ::= isSlashableValidator( Validator, Epoch ) [function]
  rule isActiveValidator( #Validator(_,_,_, ActivationEpoch, _, WithdEpoch, Slashed, _), EPOCH )
    => notBool Slashed andBool ActivationEpoch <=Int EPOCH andBool EPOCH <Int WithdEpoch

  syntax IntList ::= getActiveValidatorIndices( Epoch ) [function]
  rule [[ getActiveValidatorIndices(EP) => getActiveValidatorIndicesAux(.IntList, 0, VALIDATORS, EP) ]]
    <validator-registry> VALIDATORS </validator-registry>

  syntax IntList ::= getActiveValidatorIndicesAux( IntList, Int, ValidatorList, Epoch ) [function]
  rule getActiveValidatorIndicesAux(_,          I => I +Int 1, V VList => VList, EP )
    requires notBool isActiveValidator(V, EP)
  rule getActiveValidatorIndicesAux(Is => I Is, I => I +Int 1, V VList => VList, EP )
    requires         isActiveValidator(V, EP)
  rule getActiveValidatorIndicesAux(Is, _, .ValidatorList, _) => Is

  // Python state modifying functions
  //====================================================

  syntax KItem ::= "increaseBalance" "(" ValidatorIndex "," Gwei ")"
  rule <k> increaseBalance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => BAL +Int Delta) ...</balances>

  // Decrease validator balance by ``delta`` with underflow protection.
  syntax KItem ::= "decreaseBalance" "(" ValidatorIndex "," Gwei ")"
  rule <k> decreaseBalance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => #if Delta >Int BAL #then 0 #else BAL -Int Delta #fi) ...</balances>

  //todo next: get_epoch_committee_count

endmodule
