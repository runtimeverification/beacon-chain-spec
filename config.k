module CONFIG
  imports DOMAINS
  imports TYPES

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
        <block-roots> .Map </block-roots> //Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
        <state-roots> .Map </state-roots> //Vector[Hash, SLOTS_PER_HISTORICAL_ROOT]
        <historical-roots> .BytesList </historical-roots> //List[Hash, HISTORICAL_ROOTS_LIMIT]
        // Eth1
        <eth1-data> .Eth1Data </eth1-data>
        <eth1-data-votes> .Eth1DataList </eth1-data-votes> //List[Eth1Data, SLOTS_PER_ETH1_VOTING_PERIOD]
        <eth1-deposit-index> 0 </eth1-deposit-index>
        // Registry
        <validators> .Map </validators> //List[Validator, VALIDATOR_REGISTRY_LIMIT]
        <balances> .Map </balances> //List[Gwei, VALIDATOR_REGISTRY_LIMIT]
        // Shuffling
        <start-shard> 0 </start-shard>
        <randao-mixes> .BytesList </randao-mixes> //Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]
        <active-index-roots> .BytesList </active-index-roots> //Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]
        <compact-committees-roots> .BytesList </compact-committees-roots> //Vector[Hash, EPOCHS_PER_HISTORICAL_VECTOR]
        // Slashings
        <slashings> .Map </slashings> //Vector[Gwei, EPOCHS_PER_SLASHINGS_VECTOR]
        // Attestations
        <previous-epoch-attestations> .PendingAttestationList </previous-epoch-attestations>
                                                       //List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
        <current-epoch-attestations> .PendingAttestationList </current-epoch-attestations>
                                                       //List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
        // Crosslinks
        <previous-crosslinks> .Map </previous-crosslinks> //Vector[Crosslink, SHARD_COUNT]
        <current-crosslinks> .Map </current-crosslinks> //Vector[Crosslink, SHARD_COUNT]
        // Finality
        <justification-bits> .BitList </justification-bits> //Bitvector[JUSTIFICATION_BITS_LENGTH]
        <previous-justified-checkpoint> .Checkpoint </previous-justified-checkpoint>
        <current-justified-checkpoint> .Checkpoint </current-justified-checkpoint>
        <finalized-checkpoint> .Checkpoint </finalized-checkpoint>
      </state>
      <block>                           //Type BeaconBlock in python spec.
        <blockSlot> -1 </blockSlot>
        <parent-root> "" </parent-root>
        <state-root> "" </state-root>
        <body>                          //Type BeaconBlockBody in python spec.
          <randao-reveal> "" </randao-reveal>
          <block-eth1-data> .Eth1Data </block-eth1-data> // added "block-" prefix to name to resolve conflicting cell names
          <graffiti> "" </graffiti>
          <proposer-slashings> .Map </proposer-slashings> //List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
          <attester-slashings> .AttesterSlashingList </attester-slashings> //List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
          <attestations> .AttestationList </attestations> //List[Attestation, MAX_ATTESTATIONS]
          <deposits> .DepositList </deposits> //List[Deposit, MAX_DEPOSITS]
          <voluntary-exits> .VoluntaryExitList </voluntary-exits> //List[VoluntaryExit, MAX_VOLUNTARY_EXITS]
          <transfers> .TransferList </transfers> //List[Transfer, MAX_TRANSFERS]
        </body>
        <signature> "" </signature>
      </block>
    </beacon-chain>

endmodule
