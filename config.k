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
    block_roots: Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
    state_roots: Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
    historical_roots: List[Root, HISTORICAL_ROOTS_LIMIT]
    # Eth1
    eth1_data: Eth1Data
    eth1_data_votes: List[Eth1Data, SLOTS_PER_ETH1_VOTING_PERIOD]
    eth1_deposit_index: uint64
    # Registry
    validators: List[Validator, VALIDATOR_REGISTRY_LIMIT]
    balances: List[Gwei, VALIDATOR_REGISTRY_LIMIT]
    # Shuffling
    randao_mixes: Vector[Root, EPOCHS_PER_HISTORICAL_VECTOR]
    # Slashings
    slashings: Vector[Gwei, EPOCHS_PER_SLASHINGS_VECTOR]  # Per-epoch sums of slashed effective balances
    # Attestations
    previous_epoch_attestations: List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
    current_epoch_attestations: List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
    # Finality
    justification_bits: Bitvector[JUSTIFICATION_BITS_LENGTH]  # Bit set for every recent justified epoch
    previous_justified_checkpoint: Checkpoint  # Previous epoch snapshot
    current_justified_checkpoint: Checkpoint
    finalized_checkpoint: Checkpoint
*/
  configuration
    <beacon-chain>
      <k> $PGM:KItem </k>
      <state>                           //Type BeaconState in python spec.
        // Versioning
        <genesis-time> 0 </genesis-time>
        <slot> 0 </slot>
        <fork> .Fork </fork>
        // History
        <latest-block-header> .BlockHeader </latest-block-header>
        <block-roots> .Map </block-roots> //Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
        <state-roots> .Map </state-roots> //Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
        <historical-roots> .BytesList </historical-roots> //List[Root, HISTORICAL_ROOTS_LIMIT]
        // Eth1
        <eth1-data> .Eth1Data </eth1-data>
        <eth1-data-votes> .Eth1DataList </eth1-data-votes> //List[Eth1Data, SLOTS_PER_ETH1_VOTING_PERIOD]
        <eth1-deposit-index> 0 </eth1-deposit-index>
        // Registry
        <validators> .Map </validators> //List[Validator, VALIDATOR_REGISTRY_LIMIT]
        <balances> .Map </balances> //List[Gwei, VALIDATOR_REGISTRY_LIMIT]
        // Shuffling
        <randao-mixes> .BytesList </randao-mixes> //Vector[Bytes32, EPOCHS_PER_HISTORICAL_VECTOR]
        // Slashings
        <slashings> .Map </slashings> //Vector[Gwei, EPOCHS_PER_SLASHINGS_VECTOR]
        // Attestations
        <previous-epoch-attestations> .PendingAttestationList </previous-epoch-attestations>
                                                       //List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
        <current-epoch-attestations> .PendingAttestationList </current-epoch-attestations>
                                                       //List[PendingAttestation, MAX_ATTESTATIONS * SLOTS_PER_EPOCH]
        // Finality
        <justification-bits> .BitList </justification-bits> //Bitvector[JUSTIFICATION_BITS_LENGTH]
        <previous-justified-checkpoint> .Checkpoint </previous-justified-checkpoint>
        <current-justified-checkpoint> .Checkpoint </current-justified-checkpoint>
        <finalized-checkpoint> .Checkpoint </finalized-checkpoint>
      </state>
      <zerohashes-cache> .Map </zerohashes-cache>
    </beacon-chain>

endmodule
