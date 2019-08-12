requires "hash-tree.k"

module BEACON-CHAIN
  imports DOMAINS
  imports HASH-TREE

  // Helper functions -- Math
  //====================================================

  syntax Int ::= integerSquareroot( Int ) [function]

/*
def xor(bytes1: Bytes32, bytes2: Bytes32) -> Bytes32:
    return Bytes32(a ^ b for a, b in zip(bytes1, bytes2))
*/
  syntax Bytes ::= xor( Bytes, Bytes ) [function]
  rule xor(A, B) => chrChar(ordChar(substrString(A, 0, 1)) ^Int ordChar(substrString(B, 0, 1)))
                    +Bytes xor(substrString(A, 1, lengthString(A) -Int 1), substrString(B, 1, lengthString(B) -Int 1))
    requires lengthString(A) >Int 0 andBool lengthString(B) >Int 0
  rule xor("", "") => ""

  // Helper functions -- Crypto
  //====================================================
/*
def hash_tree_root(object: SSZSerializable) -> Hash
*/
  syntax Hash ::= hashTreeRoot( Bytes ) [function]

/*
def signing_root(object: Container) -> Hash
 */
  syntax Bytes ::= signingRoot( Bytes ) [function]

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
  syntax Bool ::= isActiveValidator( Validator, Int ) [function]
  rule isActiveValidator( VAL, EPOCH )
    => VAL.activationEpoch <=Int EPOCH andBool EPOCH <Int VAL.exitEpoch

/*
def is_slashable_validator(validator: Validator, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is slashable.
    """
    return (not validator.slashed) and (validator.activation_epoch <= epoch < validator.withdrawable_epoch)
*/
  syntax Bool ::= isSlashableValidator( Validator, Int ) [function]
  rule isActiveValidator( VAL, EPOCH )
    => notBool VAL.slashed andBool VAL.activationEpoch <=Int EPOCH andBool EPOCH <Int VAL.withdrawableEpoch

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
  syntax Bool ::= isSlashableAttestationData(AttestationData, AttestationData) [function]
  rule isSlashableAttestationData(
    #AttestationData(H1, #Checkpoint(S1EP,S1H),#Checkpoint(T1EP,T1H), CL1),
    #AttestationData(H2, #Checkpoint(S2EP,S2H),#Checkpoint(T2EP,T2H), CL2)
    ) =>
      // Double vote
      //((H1 =/=K H2 orBool S1EP =/=K S2EP orBool S1H =/=K S2H orBool T1H =/=K T2H orBool CL1 =/=K CL2) andBool
      //  T1EP ==K T2EP) orBool
      (#AttestationData(H1, #Checkpoint(S1EP,S1H),#Checkpoint(T1EP,T1H), CL1)
      =/=K #AttestationData(H2, #Checkpoint(S2EP,S2H),#Checkpoint(T2EP,T2H), CL2)
      andBool T1EP ==K T2EP) orBool
      // Surround vote
      (S1EP <Int S2EP andBool T2EP <Int T1EP)

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
  syntax Bool ::= isValidIndexedAttestation( IndexedAttestation ) [function]
  rule isValidIndexedAttestation(IAtt)
    =>      len(IAtt.custodyBit1Indices) ==Int 0
    andBool len(IAtt.custodyBit0Indices) +Int len(IAtt.custodyBit1Indices) <=Int MAX_VALIDATORS_PER_COMMITTEE
    andBool intersection(IAtt.custodyBit0Indices, IAtt.custodyBit1Indices) ==K .IntList
    andBool IAtt.custodyBit0Indices ==K sortIntList(IAtt.custodyBit0Indices)
    andBool IAtt.custodyBit1Indices ==K sortIntList(IAtt.custodyBit1Indices)
    //we do not check for BLS signature

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
  syntax Int ::= computeShuffledIndex( Int, Int, Hash ) [function]
  rule computeShuffledIndex(INDEX, COUNT, SEED) => INDEX %Int COUNT // TODO: replace mock implementation


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

  syntax IntList ::= computeCommitteeLoop( Int, Int, Hash, IntList, IntList )
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
  syntax Int ::= computeEpochOfSlot(Int) [function]
  rule computeEpochOfSlot(SLOT) => SLOT /Int SLOTS_PER_EPOCH

/*
def compute_start_slot_of_epoch(epoch: Epoch) -> Slot:
    """
    Return the start slot of ``epoch``.
    """
    return Slot(epoch * SLOTS_PER_EPOCH)
*/
  syntax Int ::= computeStartSlotOfEpoch(Int) [function]
  rule computeStartSlotOfEpoch(EPOCH) => EPOCH *Int SLOTS_PER_EPOCH

/*
def compute_activation_exit_epoch(epoch: Epoch) -> Epoch:
    """
    Return the epoch during which validator activations and exits initiated in ``epoch`` take effect.
    """
    return Epoch(epoch + 1 + ACTIVATION_EXIT_DELAY)
*/
  syntax Int ::= computeActivationExitEpoch ( Int ) [function]
  rule computeActivationExitEpoch(EP) => EP +Int 1 +Int ACTIVATION_EXIT_DELAY

/*
def compute_domain(domain_type: DomainType, fork_version: Version=Version()) -> Domain:
    """
    Return the domain for the ``domain_type`` and ``fork_version``.
    """
    return Domain(domain_type + fork_version)
*/
  syntax Domain ::= computeDomain(DomainType, Version)                [function]
  rule computeDomain(Domain_Type, Fork_Version) => Domain_Type +Bytes Fork_Version

  // Helper functions -- Beacon state accessors
  //====================================================

/*
def get_current_epoch(state: BeaconState) -> Epoch:
    """
    Return the current epoch.
    """
    return compute_epoch_of_slot(state.slot)
*/
  syntax Int ::= getCurrentEpoch( ) [function]
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
  syntax Int ::= getPreviousEpoch() [function]
  rule getPreviousEpoch() =>  #if getCurrentEpoch() ==K GENESIS_EPOCH
                                #then GENESIS_EPOCH
                                #else getCurrentEpoch() -Int 1
                              #fi

/*
def get_block_root(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the block root at the start of a recent ``epoch``.
    """
    return get_block_root_at_slot(state, compute_start_slot_of_epoch(epoch))
*/
  syntax Hash ::= getBlockRoot( Int ) [function]
  rule getBlockRoot(EP) => getBlockRootAtSlot(computeStartSlotOfEpoch(EP))

/*
def get_block_root_at_slot(state: BeaconState, slot: Slot) -> Hash:
    """
    Return the block root at a recent ``slot``.
    """
    assert slot < state.slot <= slot + SLOTS_PER_HISTORICAL_ROOT
    return state.block_roots[slot % SLOTS_PER_HISTORICAL_ROOT]
*/
  syntax Hash ::= getBlockRootAtSlot( Int ) [function]
  rule [[ getBlockRootAtSlot(SLOT) => getBlockRootAtSlotAux(SLOT %Int SLOTS_PER_HISTORICAL_ROOT)]]
    <slot> SSLOT </slot>
    requires SLOT <Int SSLOT andBool SSLOT <=Int (SLOT +Int SLOTS_PER_HISTORICAL_ROOT)

  syntax Hash ::= getBlockRootAtSlotAux( Int ) [function]
  rule [[ getBlockRootAtSlotAux(SLOT) => BLOCKROOT ]]
    <block-roots> SLOT |-> BLOCKROOT </block-roots>


/*
def get_randao_mix(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the randao mix at a recent ``epoch``.
    """
    return state.randao_mixes[epoch % EPOCHS_PER_HISTORICAL_VECTOR]
*/
  syntax Hash ::= getRandaoMix( Int ) [function]
  rule [[ getRandaoMix( EPOCH ) => getRandaoMixAux( RMS, EPOCH %Int EPOCHS_PER_HISTORICAL_VECTOR )]]
    <randao-mixes> RMS </randao-mixes>

  syntax Hash ::= getRandaoMixAux( BytesList, Int ) [function]
  rule getRandaoMixAux(RM RMS, 0) => RM
  rule getRandaoMixAux(RM RMS, I) => getRandaoMixAux(RMS, I -Int 1)
    requires I >Int 0

/*
def get_active_validator_indices(state: BeaconState, epoch: Epoch) -> Sequence[ValidatorIndex]:
    """
    Return the sequence of active validator indices at ``epoch``.
    """
    return [ValidatorIndex(i) for i, v in enumerate(state.validators) if is_active_validator(v, epoch)]
*/
  syntax IntList ::= getActiveValidatorIndices( Int ) [function]
  rule [[ getActiveValidatorIndices(EP) => getActiveValidatorIndicesAux(.IntList, 0, VALIDATORS, EP) ]]
    <validators> VALIDATORS </validators>

  syntax IntList ::= getActiveValidatorIndicesAux( IntList, Int, Map, Int ) [function]
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
  syntax Hash ::= getSeed( Int ) [function]

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
  syntax Int ::= getCommitteeCount( Int ) [function]
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
  syntax IntList ::= getCrosslinkCommittee( Int, Int ) [function]
  rule getCrosslinkCommittee(EPOCH, SHARD)
    => computeCommittee(
          getActiveValidatorIndices(EPOCH),
          getSeed(EPOCH),
          (SHARD +Int SHARD_COUNT -Int getStartShard(EPOCH)) %Int SHARD_COUNT,
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
  syntax Int ::= getStartShard( Int ) [function]
  rule [[ getStartShard(EPOCH) => getStartShardAux(
      getCurrentEpoch() +Int 1,
      (LSS +Int getShardDelta(getCurrentEpoch())) %Int SHARD_COUNT,
      EPOCH
    ) ]]
    <start-shard> LSS </start-shard>
    requires EPOCH <=Int getCurrentEpoch() +Int 1

  syntax Int ::= getStartShardAux( Int, Int, Int ) [function]
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
  syntax Int ::= getShardDelta( Int ) [function]
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
       => #fun(EPOCH
       => #fun(CommitteesPerSlot
       //=> #fun(OFFSET
       //=> #fun(SHARD
       //=> #fun(FirstCommittee
       //=> #fun(MaxRandomByte
       //=> #fun(SEED
       //=> #fun(I
       /*=> getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD,
                                     FirstCommittee, MaxRandomByte, SEED, I)*/
       //todo commented code should work but crashes with ClassCastException, even with one #fun.
       => getBeaconProposerIndexLoop(0, 0, 0, 0, .IntList, 0, "", 0)
       //   )(0)
       //   )(0/*getSeed(EPOCH)*/)
       //   )(2 ^Int 8 -Int 1)
       //   )(getCrosslinkCommittee(EPOCH, SHARD))
       //   )((getStartShard(EPOCH) +Int OFFSET) %Int SHARD_COUNT)
       //   )(CommitteesPerSlot *Int (SLOT %Int SLOTS_PER_EPOCH))
          )(getCommitteeCount(EPOCH))
          )(getCurrentEpoch())
       ]]
    <slot> SLOT </slot>

  syntax ValidatorIndex ::= getBeaconProposerIndexLoop(
                              Int, Int, Int, Int, IntList, Int, Hash, Int) [function]
  rule [[ getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I)
    =>    getBeaconProposerIndexLoopAux(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I,
                  get(FirstCommittee, (EPOCH +Int I) %Int len(FirstCommittee)) #as CandidateIndex,
                  //random_byte = hash(seed + int_to_bytes(i // 32, length=8))[i % 32]
                  getByte( hashConcat(SEED, to_bytes(I /Int 32, 8) ), I %Int 32) /*#as RandomByte*/,
                  VAL.effectiveBalance
          ) ]]
    <validators>... CandidateIndex |-> VAL ...</validators>

  syntax ValidatorIndex ::= getBeaconProposerIndexLoopAux(
                              Int, Int, Int, Int, IntList, Int, Hash, Int,
                              Int, Int, Int) [function]
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
    syntax Int ::= getAttestationDataSlot(AttestationData) [function]
    rule getAttestationDataSlot(#AttestationData(_,_, #Checkpoint(EP,_), #Crosslink(SHARD,_,_,_,_))) =>
      computeStartSlotOfEpoch(EP) +Int
        // offset
        (( SHARD +Int SHARD_COUNT -Int getStartShard(EP) ) %Int SHARD_COUNT) /Int
        // (committee_count // SLOTS_PER_EPOCH)
        (getCommitteeCount(EP) /Int SLOTS_PER_EPOCH)

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
  syntax Hash ::= getCompactCommitteesRoot(Int)
  rule getCompactCommitteesRoot(EPOCH) => 0 // TODO: fix dummy implementation


/*
def get_total_balance(state: BeaconState, indices: Set[ValidatorIndex]) -> Gwei:
    """
    Return the combined effective balance of the ``indices``. (1 Gwei minimum to avoid divisions by zero.)
    """
    return Gwei(max(sum([state.validators[index].effective_balance for index in indices]), 1))
*/
  syntax Int ::= getTotalBalance( IntList ) [function]
  rule getTotalBalance(INDICES) => maxInt(getTotalBalancePure(INDICES, 0), 1)

  syntax Int ::= getTotalBalancePure( IntList, Int ) [function]
  rule [[ getTotalBalancePure(I IL => IL, S => S +Int VAL.effectiveBalance) ]]
    <validators>... I |-> VAL ...</validators>
  rule getTotalBalancePure(.IntList, S) => S

/*
def get_total_active_balance(state: BeaconState) -> Gwei:
    """
    Return the combined effective balance of the active validators.
    """
    return get_total_balance(state, set(get_active_validator_indices(state, get_current_epoch(state))))
*/
  syntax Int ::= getTotalActiveBalance() [function]
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
// TODO: add the case requires EPOCH is None
  syntax Domain ::= getDomain( DomainType, Int ) [function]
  rule [[ getDomain(DTYPE, EPOCH) => computeDomain(DTYPE,
    #if EPOCH <Int FEPOCH #then FPREV #else FCURR #fi
  ) ]]
  <fork> #Fork(FPREV,FCURR,FEPOCH) </fork>

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
  syntax IndexedAttestation ::= getIndexedAttestation(Attestation) [function]
  rule getIndexedAttestation(#Attestation(ABITS,ADATA,CBITS,SIGN)) =>
    #IndexedAttestation(
        sortIntList(listDiff(getAttestingIndices(ADATA,ABITS), getAttestingIndices(ADATA, CBITS))),
        sortIntList(getAttestingIndices(ADATA, CBITS)),
        ADATA,
        SIGN
    )

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
  syntax IntList ::= getAttestingIndices(AttestationData, BitList) [function]
  rule getAttestingIndices(#AttestationData(_,_, #Checkpoint(EP,_), #Crosslink(SHARD,_,_,_,_)), BL) =>
    extractAttestingIndices(getCrosslinkCommittee(EP, SHARD), BL, .IntList)

  syntax IntList ::= extractAttestingIndices(IntList, BitList, IntList) [function]
  rule extractAttestingIndices(I IL => IL, true  BL => BL, AL => AL I)
  rule extractAttestingIndices(I IL => IL, false BL => BL, AL)
  rule extractAttestingIndices(.IntList,_, AL) => AL

  // Helper functions -- Beacon state mutators
  //====================================================

/*
def increase_balance(state: BeaconState, index: ValidatorIndex, delta: Gwei) -> None:
    """
    Increase the validator balance at index ``index`` by ``delta``.
    """
    state.balances[index] += delta
*/
  syntax KItem ::= "increaseBalance" "(" ValidatorIndex "," Int ")"
  rule <k> increaseBalance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => BAL +Int Delta) ...</balances>

/*
def decrease_balance(state: BeaconState, index: ValidatorIndex, delta: Gwei) -> None:
    """
    Decrease the validator balance at index ``index`` by ``delta``, with underflow protection.
    """
    state.balances[index] = 0 if delta > state.balances[index] else state.balances[index] - delta
*/
  syntax KItem ::= "decreaseBalance" "(" ValidatorIndex "," Int ")"
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
                 | initiateValidatorExitAux( Int /*index*/ , Int /*exit_queue_epoch*/ )

  rule <k> initiateValidatorExit(INDEX) => .K ...</k>
       <validators>... INDEX |-> VAL ...</validators>
    requires VAL.exitEpoch =/=K FAR_FUTURE_EPOCH

  rule <k> initiateValidatorExit(INDEX) => initiateValidatorExitAux(INDEX, exitQueueEpochAux(INDEX)) ...</k>
       <validators>... INDEX |-> VAL ...</validators>
    requires VAL.exitEpoch ==K FAR_FUTURE_EPOCH

  rule <k> initiateValidatorExitAux(INDEX, ExitQEpoch) => .K ...</k>
       <validators>
          (INDEX |-> #Validator(_,_,_,_,_,_,
            ExitEPOCH => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int getValidatorChurnLimit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi ,
            WithdrEpoch => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int getValidatorChurnLimit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi +Int MIN_VALIDATOR_WITHDRAWABILITY_DELAY) _) #as VALIDATORS
       </validators>

  syntax Int ::= exitQueueEpochAux ( Int ) [function]
  rule [[ exitQueueEpochAux(INDEX)
          => maxAux(computeActivationExitEpoch(getCurrentEpoch())
                    exitEpochsAux(VALIDATORS, .IntList) ) ]]
    <validators> VALIDATORS </validators>

  syntax IntList ::= exitEpochsAux( Map /*validators*/ , IntList /*result*/ )
  rule exitEpochsAux(_:Map (_ |-> VAL => .Map),
                     RES => VAL.exitEpoch RES )
    requires VAL.exitEpoch =/=K FAR_FUTURE_EPOCH

  rule exitEpochsAux(_:Map (_ |-> VAL => .Map),
                     RES /*unchanged*/ )
    requires VAL.exitEpoch ==K FAR_FUTURE_EPOCH

  rule exitEpochsAux(.Map, RES) => RES

  // exit_queue_churn = len([v for v in state.validator_registry if v.exit_epoch == exit_queue_epoch])
  syntax Int ::= exitQueueChurnAux ( Int /*exit_queue_epoch*/ , Map /*validator_registry*/ , Int /*result*/ ) [function]
  rule exitQueueChurnAux( ExitQEpoch, _:Map (_ |-> VAL => .Map), RES => RES +Int 1 )
    requires VAL.exitEpoch  ==K ExitQEpoch
  rule exitQueueChurnAux( ExitQEpoch, _:Map (_ |-> VAL => .Map), _ )
    requires VAL.exitEpoch =/=K ExitQEpoch
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
  syntax KItem ::= "slashValidator" "(" ValidatorIndex "," /*slashed_index*/
	                                      K                  /*whistleblower_index or .K if none*/ ")"

	  rule <k> slashValidator(SlashedINDEX, WhistleblINDEX)
	           => initiateValidatorExit(SlashedINDEX)
	           ~> slashValidatorAux(SlashedINDEX,
	                                WhistleblINDEX,
	                                getBeaconProposerIndex(),
	                                VAL.effectiveBalance /Int WHISTLEBLOWER_REWARD_QUOTIENT, //whistleblower_reward
	                                VAL.effectiveBalance /Int WHISTLEBLOWER_REWARD_QUOTIENT /Int PROPOSER_REWARD_QUOTIENT, //proposer_reward
	                                getCurrentEpoch() +Int EPOCHS_PER_SLASHINGS_VECTOR) //SlashEPOCH
	        ...</k>
	       <validators> SlashedINDEX |-> VAL ...</validators>

	  syntax KItem ::= "slashValidatorAux" "(" ValidatorIndex "," ValidatorIndex "," ValidatorIndex "," Int "," Int "," Int ")"
	  rule <k> slashValidatorAux(SlashedINDEX, WhistleblINDEX, ProposerINDEX, WhistleREWARD, ProposerREWARD, SlashEPOCH)
	       => decreaseBalance(SlashedINDEX, EffBALANCE /Int MIN_SLASHING_PENALTY_QUOTIENT)
	       ~> increaseBalance(ProposerINDEX, ProposerREWARD)
	       ~> increaseBalance(#if WhistleblINDEX ==K .ValidatorIndex #then ProposerINDEX #else WhistleblINDEX #fi,
	                          WhistleREWARD -Int ProposerREWARD)
	       ...</k>
	    <validators>
	      SlashedINDEX |-> #Validator(
	        _,_,
	        EffBALANCE,
	        _ => true, //slashed
	        _,_,_,
	        WithdEPOCH => maxInt(WithdEPOCH, SlashEPOCH) //withdrawable epoch
	      )
	      ...
	    </validators>
	    <slashings> SlashEPOCH |-> (SL => SL +Int EffBALANCE)  ...</slashings>

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
  syntax KItem ::= "processSlots" "(" Int ")"
  rule <k> processSlots(SLOT) => processSlotsLoop(SLOT) ...</k>
       <slot> SSLOT </slot>
    requires SSLOT <=Int SLOT

  syntax KItem ::= "processSlotsLoop" "(" Int ")"
  rule <k> processSlotsLoop(SLOT) =>
             processSlot()   ~>
             #if (SSLOT +Int 1) %Int SLOTS_PER_EPOCH ==K 0 #then processEpoch() #else .K #fi ~>
             incrementSlot() ~>
             processSlotsLoop(SLOT) ...</k>
       <slot> SSLOT </slot>
    requires SSLOT <Int SLOT

  rule <k> processSlotsLoop(SLOT) => .K ... </k>
       <slot> SSLOT </slot>
    requires SSLOT >=Int SLOT

  syntax KItem ::= "incrementSlot" "(" ")"
  rule <k> incrementSlot() => .K ...</k>
       <slot> SLOT => SLOT +Int 1 </slot>

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
  syntax KItem ::= "processSlot" "(" ")"
  rule <k> processSlot() =>
             processSlotAux(hashTreeRoot(""), SLOT %Int SLOTS_PER_HISTORICAL_ROOT) // TODO: fix dummy bytes
       ...</k>
       <slot> SLOT </slot>

  syntax KItem ::= "processSlotAux" "(" Hash "," Int ")"
  rule <k> processSlotAux(HTROOT, SLOT) => cacheBlockRoot(SLOT) ... </k>
       <state-roots> SLOT |-> (_ => HTROOT) </state-roots>
       <latest-block-header> #BeaconBlockHeader(_,_, BLOCKSTATEROOT =>
                                                             #if BLOCKSTATEROOT =/=K .BlockHeader
                                                             #then HTROOT   // TODO: fix dummy hash
                                                             #else BLOCKSTATEROOT #fi , _,_) </latest-block-header>

  syntax KItem ::= "cacheBlockRoot" "(" Int ")"
  rule <k> cacheBlockRoot(SLOT) => .K ...</k>
       <latest-block-header> BHEADER </latest-block-header>
       <block-roots> SLOT |-> (BLOCKROOT => signingRoot("")) </block-roots> // TODO: fix dummy bytes


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
  syntax KItem ::= "processEpoch" "(" ")"
  rule <k> processEpoch() =>
                processJustificationAndFinalization()
             ~> processCrosslinks()
             ~> processRewardsAndPenalties()
             ~> processRegistryUpdates()
             ~> processSlashings()
             ~> processFinalUpdates()
       ... </k>

/*
def get_matching_source_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    assert epoch in (get_previous_epoch(state), get_current_epoch(state))
    return state.current_epoch_attestations if epoch == get_current_epoch(state) else state.previous_epoch_attestations
*/
  syntax PendingAttestationList ::= getMatchingSourceAttestations(Int) [function]
  rule [[ getMatchingSourceAttestations(EPOCH) =>
    #if EPOCH ==K getCurrentEpoch() #then CEA #else PEA #fi ]]
    <current-epoch-attestations> CEA </current-epoch-attestations>
    <previous-epoch-attestations> PEA </previous-epoch-attestations>


/*
def get_matching_target_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    return [
        a for a in get_matching_source_attestations(state, epoch)
        if a.data.target.root == get_block_root(state, epoch)
    ]
*/
  syntax PendingAttestationList ::= getMatchingTargetAttestations(Int) [function]
  rule getMatchingTargetAttestations(EPOCH) =>
         filterOutNonMatchingTargets(getMatchingSourceAttestations(EPOCH), EPOCH, .PendingAttestationList)

  syntax PendingAttestationList ::= filterOutNonMatchingTargets(PendingAttestationList, Int, PendingAttestationList)
  rule filterOutNonMatchingTargets(PA PAL => PAL, EPOCH, PAL' => PAL' PA)
    requires PA.data.target.root ==K getBlockRoot(EPOCH)
  rule filterOutNonMatchingTargets(PA PAL => PAL, EPOCH, PAL')
    requires PA.data.target.root =/=K getBlockRoot(EPOCH)
  rule filterOutNonMatchingTargets(.PendingAttestationList, EPOCH, PAL') => PAL'

/*
def get_matching_head_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    return [
        a for a in get_matching_source_attestations(state, epoch)
        if a.data.beacon_block_root == get_block_root_at_slot(state, get_attestation_data_slot(state, a.data))
    ]
*/
  syntax PendingAttestationList ::= getMatchingHeadAttestations(Int) [function]
  rule getMatchingHeadAttestations(EPOCH) =>
         filterOutNonMatchingHeads(getMatchingSourceAttestations(EPOCH), .PendingAttestationList)

  syntax PendingAttestationList ::= filterOutNonMatchingHeads(PendingAttestationList, PendingAttestationList)
  rule filterOutNonMatchingHeads(PA PAL => PAL, PAL' => PAL' PA)
    requires PA.data.beaconBlockRoot ==K getBlockRootAtSlot(getAttestationDataSlot(PA.data))
  rule filterOutNonMatchingHeads(PA PAL => PAL, PAL')
    requires PA.data.beaconBlockRoot =/=K getBlockRootAtSlot(getAttestationDataSlot(PA.data))
  rule filterOutNonMatchingHeads(.PendingAttestationList, PAL') => PAL'


/*
def get_unslashed_attesting_indices(state: BeaconState,
                                    attestations: Sequence[PendingAttestation]) -> Set[ValidatorIndex]:
    output = set()  # type: Set[ValidatorIndex]
    for a in attestations:
        output = output.union(get_attesting_indices(state, a.data, a.aggregation_bits))
    return set(filter(lambda index: not state.validators[index].slashed, list(output)))
*/
  syntax IntList ::= getUnslashedAttestingIndices(PendingAttestationList) [function]
  rule getUnslashedAttestingIndices(PAL) => filterOutSlashedIndices(getAttestingIndicesLoop(PAL, .IntList))

  // merging, instead of concatenation, of lists is performed
  syntax IntList ::= getAttestingIndicesLoop(PendingAttestationList, IntList) [function]
  rule getAttestingIndicesLoop(PA PAL => PAL, IL => (IL ++IntList getAttestingIndices(PA.data, PA.aggregationBits)))
  rule getAttestingIndicesLoop(.PendingAttestationList, IL) => IL

  syntax IntList ::= filterOutSlashedIndices(IntList) [function]
  rule [[ filterOutSlashedIndices(I IL) => #if VAL.slashed
                                           #then filterOutSlashedIndices(IL)
                                           #else I filterOutSlashedIndices(IL)
                                           #fi ]]
    <validators>... I |-> VAL ...</validators>

  rule filterOutSlashedIndices(.IntList) => .IntList

/*
def get_attesting_balance(state: BeaconState, attestations: Sequence[PendingAttestation]) -> Gwei:
    return get_total_balance(state, get_unslashed_attesting_indices(state, attestations))
*/
  syntax Int ::= getAttestingBalance(PendingAttestationList) [function]
  rule getAttestingBalance(PAL) => getTotalBalance(getUnslashedAttestingIndices(PAL))

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
  syntax CrosslinkIntListPair ::= getWinningCrosslinkAndAttestingIndices(Int, Int) [function]

  // attestations == getMatchingShardSourceAttestations(EPOCH,SHARD)
  //                 filterMatchingShard(getMatchingSourceAttestations(EP), SHARD, .PendingAttestationList)
  // crosslinks == getCrosslinksOfMatchingShardSourceAttestations(EPOCH, SHARD)
  //               getShardCrosslinks(crosslinksOf(attestations), SHARD, .CrosslinkList)
  // winning_crosslink == getWinningCrosslink(crosslinks, epoch, shard)
  //                      maxBasedOnDataRoot(maxBasedOnBalance(crosslinks, epoch, shard))
  // winning_attestations == filterMatchingCrosslink( attestations, winning_crosslink, .PendingAttestationList)

  rule getWinningCrosslinkAndAttestingIndices(EPOCH, SHARD) =>
    #crosslinkIntListPair( //winning crosslink
                           getWinningCrosslink(EPOCH,SHARD),
                           //Unslashed attesting indices (list)
                           getUnslashedAttestingIndices(
                             filterMatchingCrosslink(
                               getMatchingShardSourceAttestations(EPOCH,SHARD),
                               getWinningCrosslink(EPOCH,SHARD),
                               .PendingAttestationList))
                         )

  syntax PendingAttestationList ::= getMatchingShardSourceAttestations(Int, Int)      [function]
  rule getMatchingShardSourceAttestations(EPOCH,SHARD)
       => filterMatchingShard(getMatchingSourceAttestations(EPOCH),
                                   SHARD,
                                   .PendingAttestationList)

  syntax CrosslinkList ::= getCrosslinksOfMatchingShardSourceAttestations(Int, Int) [function]
  rule getCrosslinksOfMatchingShardSourceAttestations(EPOCH, SHARD)
       => getShardCrosslinks(crosslinksOf(getMatchingShardSourceAttestations(EPOCH,SHARD)), SHARD, .CrosslinkList)

  syntax Crosslink ::= getWinningCrosslink(Int, Int) [function]
  rule getWinningCrosslink(EPOCH,SHARD)
       => maxBasedOnDataRoot(maxBasedOnDataRoot(maxBasedOnBalance(
                                                   getCrosslinksOfMatchingShardSourceAttestations(EPOCH, SHARD),
                                                   EPOCH,
                                                   SHARD)))

  // extracts the list of attestations for the given shard
  syntax PendingAttestationList ::= filterMatchingShard(PendingAttestationList, Int, PendingAttestationList) [function]
  rule filterMatchingShard(PA PAL => PAL, SHARD, PAL' => PAL' PA)
    requires PA.data.crosslink.shard ==K SHARD
  rule filterMatchingShard(PA PAL => PAL, SHARD, PAL')
    requires PA.data.crosslink.shard =/=K SHARD
  rule filterMatchingShard(.PendingAttestationList, _, PAL') => PAL'

  // extracts the list of crosslinks matching the condition given for 'crosslinks' in the python code
  syntax CrosslinkList ::= getShardCrosslinks(CrosslinkList, Int, CrosslinkList) [function]
  rule [[ getShardCrosslinks(C CL => CL, SHARD, CL' => CL' C) ]]
    <current-crosslinks> SHARD |-> CURRC </current-crosslinks>
      requires hashTreeRoot(CURRC) ==K C.parentRoot
      //orBool hashTreeRoot(CURRC) ==K hashTreeRoot(C)  //TODO: fix hashTreeRoot condition

  rule [[ getShardCrosslinks(C CL => CL, SHARD, CL') ]]
    <current-crosslinks> SHARD |-> CURRC </current-crosslinks>
      requires hashTreeRoot(CURRC) =/=K C.parentRoot
      //andBool hashTreeRoot(CURRC) =/=K hashTreeRoot(C) //TODO: fix hashTreeRoot condition

  rule getShardCrosslinks(.CrosslinkList, SHARD, CL') => CL'

  // extracts the crosslinks of a given attestation list
  syntax CrosslinkList ::= crosslinksOf(PendingAttestationList) [function]
  rule crosslinksOf(PA PAL) => PA.data.crosslink crosslinksOf(PAL)
  rule crosslinksOf(.PendingAttestationList) => .CrosslinkList

  // extract from input the crosslinks with the maximum attestation balance
  syntax CrosslinkList ::= maxBasedOnBalance(CrosslinkList, Int, Int) [function]
  rule maxBasedOnBalance(CL, EP, SHARD) =>
    maxBasedOnBalanceAux(CL, EP, SHARD, findMaxBalance(CL, EP, SHARD, 0), .CrosslinkList)

  syntax Int ::= computeAttestingBalanceOfMatchingCrosslink(Int, Int, Crosslink)    [function]
  rule computeAttestingBalanceOfMatchingCrosslink(EP, SHARD, C)
       => getAttestingBalance(filterMatchingCrosslink(
                                  getMatchingShardSourceAttestations(EP,SHARD), C, .PendingAttestationList))

  syntax CrosslinkList ::= maxBasedOnBalanceAux(CrosslinkList, Int, Int, Int, CrosslinkList) [function]
  rule maxBasedOnBalanceAux(C CL => CL, EP, SHARD, MAXBAL, CL' => CL' C)
    requires computeAttestingBalanceOfMatchingCrosslink(EP, SHARD, C) ==K MAXBAL
  rule maxBasedOnBalanceAux(C CL => CL, EP, SHARD, MAXBAL, CL')
    requires computeAttestingBalanceOfMatchingCrosslink(EP, SHARD, C) =/=K MAXBAL
  rule maxBasedOnBalanceAux(.CrosslinkList, EP, SHARD, MAXBAL, CL') => CL'

  syntax Int ::= findMaxBalance(CrosslinkList, Int, Int, Int) [function]
  rule findMaxBalance(C CL => CL,
                      EP,
                      SHARD,
                      BALANCE => computeAttestingBalanceOfMatchingCrosslink(EP, SHARD, C) )
    requires computeAttestingBalanceOfMatchingCrosslink(EP, SHARD, C) >Int BALANCE

  rule findMaxBalance(C CL => CL,
                      EP,
                      SHARD,
                      BALANCE)
    requires computeAttestingBalanceOfMatchingCrosslink(EP, SHARD, C) <=Int BALANCE
  rule findMaxBalance(.CrosslinkList, EP, SHARD, BALANCE) => BALANCE

  syntax PendingAttestationList ::= filterMatchingCrosslink(PendingAttestationList, Crosslink, PendingAttestationList) [function]
  rule filterMatchingCrosslink(PA PAL => PAL, C, PAL' => PAL' PA)
    requires PA.data.crosslink ==K C
  rule filterMatchingCrosslink(PA PAL => PAL, C, PAL')
    requires PA.data.crosslink =/=K C
  rule filterMatchingCrosslink(.PendingAttestationList, C, PAL') => PAL'

  // get the crosslink with the maximum data root hash value
  syntax Crosslink ::= maxBasedOnDataRoot(CrosslinkList) [function]
  rule maxBasedOnDataRoot(C CL) => maxBasedOnDataRootAux(CL, C, C.dataRoot)

  syntax Crosslink ::= maxBasedOnDataRootAux(CrosslinkList, Crosslink, Hash) [function]
  rule maxBasedOnDataRootAux(C CL => CL, MAXC => C, MAXCDROOT => C.dataRoot)
    requires {C.dataRoot}:>String >String MAXCDROOT
  rule maxBasedOnDataRootAux(C CL => CL, MAXC, MAXCDROOT)
    requires {C.dataRoot}:>String <=String MAXCDROOT
  rule maxBasedOnDataRootAux(.CrosslinkList, MAXC, MAXCDROOT) => MAXC

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
  syntax KItem ::= "processJustificationAndFinalization" "(" ")"

  // too early to proceed with processing
  rule <k> (processJustificationAndFinalization() => .K) ... </k>
    requires getCurrentEpoch() <=Int GENESIS_EPOCH +Int 1

  // proceed with processing
  rule <k> processJustificationAndFinalization()
           => updateJustificationPrev(getPreviousEpoch())
           ~> updateJustificationCurr(getCurrentEpoch())
           ~> updateFinalization(PrevJustCHECKP, CurrJustCHECKP)... </k>
       <previous-justified-checkpoint> PrevJustCHECKP => CurrJustCHECKP </previous-justified-checkpoint>
       <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
       <justification-bits> Bits => shiftRight(Bits) </justification-bits>
    requires getCurrentEpoch() >Int GENESIS_EPOCH +Int 1

  syntax KItem ::= "updateJustificationPrev" "(" Int ")"
  rule <k> updateJustificationPrev(EPOCH) => .K ... </k>
       <current-justified-checkpoint>
          CurrJustCHECKP => #Checkpoint(EPOCH, getBlockRoot(EPOCH))
       </current-justified-checkpoint>
       <justification-bits> Bits => setBitAt(Bits, 1, true) </justification-bits>
    requires getAttestingBalance(getMatchingTargetAttestations(EPOCH)) *Int 3 >=Int getTotalActiveBalance() *Int 2
  rule <k> updateJustificationPrev(EPOCH) => .K ... </k>
       <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
       <justification-bits> Bits </justification-bits>
    requires notBool getAttestingBalance(getMatchingTargetAttestations(EPOCH)) *Int 3 >=Int getTotalActiveBalance() *Int 2

  syntax KItem ::= "updateJustificationCurr" "(" Int ")"
  rule <k> updateJustificationCurr(EPOCH) => .K ... </k>
       <current-justified-checkpoint>
          CurrJustCHECKP => #Checkpoint(EPOCH, getBlockRoot(EPOCH))
       </current-justified-checkpoint>
       <justification-bits> Bits => setBitAt(Bits, 0, true) </justification-bits>
    requires getAttestingBalance(getMatchingTargetAttestations(EPOCH)) *Int 3 >=Int getTotalActiveBalance() *Int 2
  rule <k> updateJustificationCurr(EPOCH) => .K ... </k>
       <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
       <justification-bits> Bits </justification-bits>
    requires notBool getAttestingBalance(getMatchingTargetAttestations(EPOCH)) *Int 3 >=Int getTotalActiveBalance() *Int 2

  syntax KItem ::= "updateFinalization" "(" Checkpoint "," Checkpoint ")"
  rule <k> updateFinalization(OldPrevJustCP, OldCurrJustCP)
           => updateFinalizedCheckpoint1(OldPrevJustCP, Bits)
           ~> updateFinalizedCheckpoint2(OldPrevJustCP, Bits)
           ~> updateFinalizedCheckpoint3(OldCurrJustCP, Bits)
           ~> updateFinalizedCheckpoint4(OldCurrJustCP, Bits) ... </k>
       <justification-bits> Bits </justification-bits>

  // if all(bits[1:4]) and old_previous_justified_checkpoint.epoch + 3 == current_epoch:
  syntax KItem ::= "updateFinalizedCheckpoint1" "(" Checkpoint "," BitList ")"
  rule <k> updateFinalizedCheckpoint1(OldPrevJustCP, Bits) => .K ... </k>
       <finalized-checkpoint>
         FCP => #if allOnes(slice(Bits, 1, 4)) andBool OldPrevJustCP.epoch +Int 3 ==K getCurrentEpoch()
                #then OldPrevJustCP
                #else FCP
                #fi
       </finalized-checkpoint>

  // if all(bits[1:3]) and old_previous_justified_checkpoint.epoch + 2 == current_epoch:
  syntax KItem ::= "updateFinalizedCheckpoint2" "(" Checkpoint "," BitList ")"
  rule <k> updateFinalizedCheckpoint2(OldPrevJustCP, Bits) => .K ... </k>
       <finalized-checkpoint>
         FCP => #if allOnes(slice(Bits, 1, 3)) andBool OldPrevJustCP.epoch +Int 2 ==K getCurrentEpoch()
                #then OldPrevJustCP
                #else FCP
                #fi
       </finalized-checkpoint>

  // if all(bits[0:3]) and old_current_justified_checkpoint.epoch + 2 == current_epoch:
  syntax KItem ::= "updateFinalizedCheckpoint3" "(" Checkpoint "," BitList ")"
  rule <k> updateFinalizedCheckpoint3(OldCurrJustCP, Bits) => .K ... </k>
       <finalized-checkpoint>
         FCP => #if allOnes(slice(Bits, 0, 3)) andBool OldCurrJustCP.epoch +Int 2 ==K getCurrentEpoch()
                #then OldCurrJustCP
                #else FCP
                #fi
       </finalized-checkpoint>

  // if all(bits[0:2]) and old_current_justified_checkpoint.epoch + 1 == current_epoch:
  syntax KItem ::= "updateFinalizedCheckpoint4" "(" Checkpoint "," BitList ")"
  rule <k> updateFinalizedCheckpoint4(OldCurrJustCP, Bits) => .K ... </k>
       <finalized-checkpoint>
         FCP => #if allOnes(slice(Bits, 0, 2)) andBool OldCurrJustCP.epoch +Int 1 ==K getCurrentEpoch()
                #then OldCurrJustCP
                #else FCP
                #fi
       </finalized-checkpoint>

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
  syntax KItem ::= "processCrosslinks" "(" ")"
  rule <k> processCrosslinks()
           => processCrosslinksForEpoch(getPreviousEpoch())
           ~> processCrosslinksForEpoch(getCurrentEpoch()) ... </k>
       <previous-crosslinks> PCL => CCL </previous-crosslinks>
       <current-crosslinks> CCL  </current-crosslinks>

  syntax KItem ::= "processCrosslinksForEpoch" "(" Int ")"
  rule <k> processCrosslinksForEpoch(EP) => processCrosslinksForEpochLoop(0, getCommitteeCount(EP), EP) ... </k>

  syntax KItem ::= "processCrosslinksForEpochLoop" "(" Int "," Int "," Int ")"
  rule <k> processCrosslinksForEpochLoop(OFFSET => OFFSET +Int 1, COUNT, EP) ... </k>
       <current-crosslinks>...
         SHARD |-> (C => #if ( 3 *Int getTotalBalance(getWinningCrosslinkAndAttestingIndices(EP, SHARD).intList)
                                 >=Int 2 *Int getTotalBalance(getCrosslinkCommittee(EP, SHARD)) )
                         #then getWinningCrosslinkAndAttestingIndices(EP, SHARD).crosslink
                         #else C
                         #fi
                   )
       ...</current-crosslinks>
    requires OFFSET <Int COUNT andBool SHARD ==K (getStartShard(EP) +Int OFFSET)

  rule <k> processCrosslinksForEpochLoop(OFFSET, COUNT, EP) => .K ... </k>
    requires OFFSET >=Int COUNT


/*
def get_base_reward(state: BeaconState, index: ValidatorIndex) -> Gwei:
    total_balance = get_total_active_balance(state)
    effective_balance = state.validators[index].effective_balance
    return Gwei(effective_balance * BASE_REWARD_FACTOR // integer_squareroot(total_balance) // BASE_REWARDS_PER_EPOCH)
*/
  syntax Int ::= getBaseReward( Int ) [function]
  rule [[ getBaseReward(INDEX)
          => VAL.effectiveBalance *Int BASE_REWARD_FACTOR
             /Int integerSquareroot(getTotalActiveBalance())
             /Int BASE_REWARDS_PER_EPOCH ]]
    <validators> ... INDEX |-> VAL ... </validators>

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
  syntax MapMapPair ::= getAttestationDeltas() [function]
  rule getAttestationDeltas()
       => #mapMapPair(
            // Rewards
            delayMicroRewards(microIncentivesForRewards())
            ,
            // Penalties
            inactivityPenalty(microIncentivesForPenalties())
       )

  // First (inner) step in computing rewards/penalties
  syntax Map ::= microIncentivesForRewards() [function]
  rule microIncentivesForRewards() => microIncentives().map1

  syntax Map ::= microIncentivesForPenalties() [function]
  rule microIncentivesForPenalties() => microIncentives().map2

  syntax MapMapPair ::= microIncentives() [function]
  rule microIncentives() =>
         loopOverEligibleValidatorIndices(
           getEligibleValidatorIndices(getPreviousEpoch()),
           getUnslashedAttestingIndices(getMatchingHeadAttestations(getPreviousEpoch())),
           getTotalBalance(getUnslashedAttestingIndices(getMatchingHeadAttestations(getPreviousEpoch()))),
           microIncentivesAfterTargetAtt() )

  syntax MapMapPair ::= microIncentivesAfterTargetAtt() [function]
  rule microIncentivesAfterTargetAtt() =>
         loopOverEligibleValidatorIndices(
           getEligibleValidatorIndices(getPreviousEpoch()),
           getUnslashedAttestingIndices(getMatchingTargetAttestations(getPreviousEpoch())),
           getTotalBalance(getUnslashedAttestingIndices(getMatchingTargetAttestations(getPreviousEpoch()))),
           microIncentivesAfterSourceAtt() )

  syntax MapMapPair ::= microIncentivesAfterSourceAtt() [function]
  rule microIncentivesAfterSourceAtt() =>
         loopOverEligibleValidatorIndices(
           getEligibleValidatorIndices(getPreviousEpoch()),
           getUnslashedAttestingIndices(getMatchingSourceAttestations(getPreviousEpoch())),
           getTotalBalance(getUnslashedAttestingIndices(getMatchingSourceAttestations(getPreviousEpoch()))),
           #mapMapPair( initMapOfSize(numOfValidators()), initMapOfSize(numOfValidators())) )

  syntax MapMapPair ::= loopOverEligibleValidatorIndices(IntList, IntList, Int, MapMapPair) [function]
  rule loopOverEligibleValidatorIndices(I IL => IL,
                       UnslashedIndices,
                       AttestingBalance,
                       #mapMapPair(Rewards => #if contains(I, UnslashedIndices)
                                              #then Rewards[I <- ({Rewards[I]}:>Int +Int getBaseReward(I) *Int AttestingBalance)]
                                              #else Rewards
                                              #fi,
                                  Penalties => #if notBool contains(I, UnslashedIndices)
                                               #then Penalties[I <- ({Penalties[I]}:>Int +Int getBaseReward(I))]
                                               #else Penalties
                                               #fi) )

  rule loopOverEligibleValidatorIndices(.IntList, _, _, RewardsPenalties) => RewardsPenalties

  // Second step in computing rewards
  syntax Map ::= delayMicroRewards(Map) [function]
  rule delayMicroRewards(Rewards) =>
         loopOverUnslashedAttestingIndices(
           getUnslashedAttestingIndices(getMatchingSourceAttestations(getPreviousEpoch())),
           Rewards
         )

  syntax Map ::= loopOverUnslashedAttestingIndices(IntList, Map) [function]
  rule loopOverUnslashedAttestingIndices(
         I IL => IL,
         Rewards => (updateMinDelayAttReward(Rewards, I))[I <- ({(updateMinDelayAttReward(Rewards, I))[I]}:>Int
                                  +Int (computeMaxAttReward(I, computeProposerReward(I))
                                        *Int (SLOTS_PER_EPOCH
                                              +Int MIN_ATTESTATION_INCLUSION_DELAY
                                              -Int findMinDelayAttestation(
                                                     filterAttForIndex(getMatchingSourceAttestations(getPreviousEpoch()), I)
                                                   ).inclusionDelay )
                                        /Int SLOTS_PER_EPOCH)) ]
       )
  rule loopOverUnslashedAttestingIndices(.IntList, Rewards) => Rewards

  syntax Map ::= updateMinDelayAttReward(Map, Int) [function]
  rule updateMinDelayAttReward(Rewards, I) =>
          updateAttProposerReward(
            Rewards,
            findMinDelayAttestation(filterAttForIndex(getMatchingSourceAttestations(getPreviousEpoch()), I)),
            computeProposerReward(I))

  // rewards[attestation.proposer_index] += proposer_reward
  syntax Map ::= updateAttProposerReward(Map /*Rewards*/, PendingAttestation /*attestation*/, Int /*proposer_reward*/ ) [function]
  rule updateAttProposerReward(Rewards, Attestation, PropReward)
       => Rewards[Attestation.proposerIndex <- {Rewards[Attestation.proposerIndex]}:>Int +Int PropReward]

  // max_attester_reward = get_base_reward(state, index) - proposer_reward
  syntax Int ::= computeMaxAttReward(Int /*Proposer index*/ , Int /*proposer reward*/) [function]
  rule computeMaxAttReward(INDEX, REWARD) => getBaseReward(INDEX) -Int REWARD

  // proposer_reward = Gwei(get_base_reward(state, index) // PROPOSER_REWARD_QUOTIENT)
  syntax Int ::= computeProposerReward(Int /*proposer index*/) [function]
  rule computeProposerReward(INDEX) => getBaseReward(INDEX) /Int PROPOSER_REWARD_QUOTIENT

  /*
  attestation = min([
              a for a in matching_source_attestations
              if index in get_attesting_indices(state, a.data, a.aggregation_bits)
          ], key=lambda a: a.inclusion_delay)
  */
  syntax PendingAttestationList ::= filterAttForIndex(PendingAttestationList, Int) [function]
  rule filterAttForIndex(PA PAL, INDEX)
       => #if contains(INDEX, getAttestingIndices(PA.data, PA.aggregationBits))
          #then PA filterAttForIndex(PAL, INDEX)
          #else filterAttForIndex(PAL, INDEX)
          #fi
  rule filterAttForIndex(.PendingAttestationList, _) => .PendingAttestationList

  syntax PendingAttestation ::= findMinDelayAttestation(PendingAttestationList) [function]
  rule findMinDelayAttestation(PA PAL) => findMinDelayAttestationAux(PAL, PA)

  syntax PendingAttestation ::= findMinDelayAttestationAux(PendingAttestationList, PendingAttestation /*min delay attestation*/) [function]
  rule findMinDelayAttestationAux(
         PA PAL => PAL,
         MinDelayPA => #if PA.inclusionDelay <Int MinDelayPA.inclusionDelay
                       #then PA
                       #else MinDelayPA
                       #fi
       )
  rule findMinDelayAttestationAux(.PendingAttestationList, MinDelayPA) => MinDelayPA

  // Second step in computing penalties
  syntax Map ::= inactivityPenalty(Map) [function]
  rule inactivityPenalty(Penalties) =>
         #if computeFinalityDelay() >Int MIN_EPOCHS_TO_INACTIVITY_PENALTY
         #then inactivityPenaltyAux(Penalties)
         #else Penalties
         #fi

  syntax Map ::= inactivityPenaltyAux(Map) [function]
  rule inactivityPenaltyAux(Penalties)
       => loopOverEligibleValsForPen(
            getEligibleValidatorIndices(getPreviousEpoch()),
            getUnslashedAttestingIndices(getMatchingTargetAttestations(getPreviousEpoch())),
            Penalties)

  syntax Map ::= loopOverEligibleValsForPen(IntList, IntList, Map) [function]
  rule [[ loopOverEligibleValsForPen(
         I IL => IL,
         UnslashedIndices,
         Penalties => #if notBool contains(I, UnslashedIndices)
                      #then (updateBasePenalties(Penalties, I))[I <- {(updateBasePenalties(Penalties, I))[I]}:>Int
                                +Int (VAL.effectiveBalance *Int computeFinalityDelay() /Int INACTIVITY_PENALTY_QUOTIENT)]
                      #else updateBasePenalties(Penalties, I)
                      #fi ) ]]
       <validators> ... I |-> VAL ... </validators>

  rule loopOverEligibleValsForPen(.IntList, _, Penalties) => Penalties

  // finality_delay = previous_epoch - state.finalized_checkpoint.epoch
  syntax Int ::= computeFinalityDelay() [function]
  rule [[ computeFinalityDelay() => getPreviousEpoch() -Int FCP.epoch ]]
       <finalized-checkpoint> FCP </finalized-checkpoint>

  // penalties[index] += Gwei(BASE_REWARDS_PER_EPOCH * get_base_reward(state, index))
  syntax Map ::= updateBasePenalties(Map, Int) [function]
  rule updateBasePenalties(Penalties, INDEX)
       => Penalties[INDEX <- {Penalties[INDEX]}:>Int +Int (BASE_REWARDS_PER_EPOCH *Int getBaseReward(INDEX))]

  syntax Map ::= initMapOfSize(Int) [function]
  rule initMapOfSize(I) => (I -Int 1 |-> 0) initMapOfSize(I -Int 1)
    requires I >Int 0
  rule initMapOfSize(0) => .Map

  syntax Int ::= numOfValidators() [function]
  rule [[ numOfValidators() => size(ValMap) ]]
       <validators> ValMap </validators>

  syntax IntList ::= getEligibleValidatorIndices(Int) [function]
  rule [[ getEligibleValidatorIndices(PrevEP) => getEligibleValidatorIndicesLoop(PrevEP, 0, size(VMap), .IntList) ]]
    <validators> VMap </validators>

  syntax IntList ::= getEligibleValidatorIndicesLoop(Int, Int, Int, IntList) [function]
  rule [[ getEligibleValidatorIndicesLoop(PrevEP, I, N, IL)
          => #if isActiveValidator(VAL, PrevEP) orBool (VAL.slashed andBool PrevEP +Int 1 <Int VAL.withdrawableEpoch)
             #then getEligibleValidatorIndicesLoop(PrevEP, I +Int 1, N, IL I)
             #else getEligibleValidatorIndicesLoop(PrevEP, I +Int 1, N, IL)
             #fi ]]
    <validators> ... I |-> VAL ... </validators>
    requires I <Int N

  rule getEligibleValidatorIndicesLoop(_, I, N, IL) => IL
    requires I >=Int N

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
  syntax MapMapPair ::= getCrosslinkDeltas() [function]
  rule getCrosslinkDeltas() => getCrosslinkDeltasOffsetLoop(
                                 0,                                             // Offset counter
                                 getCommitteeCount(getPreviousEpoch()),         // Offset upper bound
                                 getPreviousEpoch(),                            // Previous epoch
                                 #mapMapPair(
                                   initMapOfSize(numOfValidators()),               // Rewards
                                   initMapOfSize(numOfValidators()))               // Penalties
                                 )

  // outer offset loop
  syntax MapMapPair ::= getCrosslinkDeltasOffsetLoop(Int, Int, Int, MapMapPair) [function]
  rule getCrosslinkDeltasOffsetLoop(
         Offset => Offset +Int 1, N, EP,
         RewPen => getCrosslinkDeltasIndexLoop(
                      getCrosslinkCommittee(EP, getOffsetShard(Offset)),                                            // Crosslink committee
                      getWinningCrosslinkAndAttestingIndices(EP, getOffsetShard(Offset)).intList,                   // Attesting indices
                      getTotalBalance(getWinningCrosslinkAndAttestingIndices(EP, getOffsetShard(Offset)).intList),  // Attesting balance
                      getTotalBalance(getCrosslinkCommittee(EP, getOffsetShard(Offset))),                           // Committee balance
                      RewPen                                                                                        // Rewards and Penalties
                    )
       )
    requires Offset <Int N
  rule getCrosslinkDeltasOffsetLoop(Offset, N, _, RewPen) => RewPen
    requires Offset >=Int N

  // inner index loop
  syntax MapMapPair ::= getCrosslinkDeltasIndexLoop(IntList, IntList, Int, Int, MapMapPair) [function]
  rule getCrosslinkDeltasIndexLoop(
         INDEX IL => IL,
         AttestingIndices,
         AttestingBalance,
         CommitteeBalance,
         #mapMapPair(Rewards, Penalties)
           => #if contains(INDEX, AttestingIndices)
              #then #mapMapPair(
                      Rewards[INDEX <- ({Rewards[INDEX]}:>Int +Int getBaseReward(INDEX) *Int AttestingBalance /Int CommitteeBalance)],
                      Penalties)
              #else #mapMapPair(
                      Rewards,
                      Penalties[INDEX <- ({Penalties[INDEX]}:>Int +Int getBaseReward(INDEX))])
              #fi
       )
  rule getCrosslinkDeltasIndexLoop(.IntList, _, _, _, RewPen) => RewPen

  syntax Int ::= getOffsetShard(Int) [function]
  rule getOffsetShard(Offset) => (getStartShard(getPreviousEpoch()) +Int Offset) %Int SHARD_COUNT

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
  syntax KItem ::= "processRewardsAndPenalties" "(" ")"
  rule <k> processRewardsAndPenalties()
       => #if getCurrentEpoch() ==K GENESIS_EPOCH
          #then .K
          #else processRewardsAndPenaltiesLoop(
                  0,
                  numOfValidators(),
                  getAttestationDeltas(),
                  getCrosslinkDeltas())
          #fi
       ... </k>

  syntax KItem ::= "processRewardsAndPenaltiesLoop" "(" Int "," Int "," MapMapPair "," MapMapPair ")"
  rule <k> (. => increaseBalance(INDEX, {Rewards1[INDEX]}:>Int +Int {Rewards2[INDEX]}:>Int)
              ~> decreaseBalance(INDEX, {Penalties1[INDEX]}:>Int +Int {Penalties2[INDEX]}:>Int)
           ) ~> processRewardsAndPenaltiesLoop(
                   INDEX => INDEX +Int 1,
                   N,
                   #mapMapPair(Rewards1, Penalties1),
                   #mapMapPair(Rewards2, Penalties2)
                 )
       ... </k>
    requires INDEX <Int N
  rule <k> processRewardsAndPenaltiesLoop(INDEX, N, _, _) => .K ... </k>
    requires INDEX >=Int N

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
  syntax KItem ::= "processRegistryUpdates" "(" ")"
  rule <k> processRegistryUpdates()
           => processRegistryUpdatesLoop1(VALIDATORS)
           ~> processActivationQueue()
         ...
       </k>
       <validators> VALIDATORS </validators>

  //we will process validators in any order, not strictly increasing index like in python
  syntax KItem ::= "processRegistryUpdatesLoop1" "(" Map ")" //validators
  rule <k> (. => #if isActiveValidator(VAL, getCurrentEpoch())
                      andBool VAL.effectiveBalance <=Int EJECTION_BALANCE
                    #then initiateValidatorExit(INDEX)
                    #else .K
                 #fi
           )
           ~> processRegistryUpdatesLoop1(_:Map (INDEX |-> VAL => .Map) )
       ...</k>
       <validators>... INDEX |-> (#Validator(_,_,_,_,
          ActEligibilityEpoch
          => #if ActEligibilityEpoch ==Int FAR_FUTURE_EPOCH
                 andBool VAL.effectiveBalance >=Int MAX_EFFECTIVE_BALANCE
                #then getCurrentEpoch()
                #else ActEligibilityEpoch
             #fi,
          _,_,_) #as VAL) ...</validators>

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
       <validators>... INDEX |-> #Validator(_,_,_,_,_, ActEpoch, _,_) ...</validators>
    requires I >Int 0
             andBool ActEpoch =/=K FAR_FUTURE_EPOCH

  rule processActivationQueue(.IntList, _) => .K
  rule processActivationQueue(       _, 0) => .K

  /*
  index for index, validator in enumerate(state.validator_registry) if
        validator.activation_eligibility_epoch != FAR_FUTURE_EPOCH and
        validator.activation_epoch >= get_delayed_activation_exit_epoch(state.finalized_epoch) */
  syntax IntList ::= getActivationQueueUnsorted( Map /*state.validator_registry*/, IntList /*result*/ ) [function]
  rule [[ getActivationQueueUnsorted(_:Map (INDEX |-> VAL => .Map),  IL => IL INDEX) ]]
       <finalized-checkpoint> #Checkpoint(FinalizedEpoch, RootHash) </finalized-checkpoint>
    requires VAL.activationEligibilityEpoch =/=K FAR_FUTURE_EPOCH
         andBool VAL.activationEpoch >=Int computeActivationExitEpoch(FinalizedEpoch)

  rule [[ getActivationQueueUnsorted(_:Map (INDEX |-> VAL => .Map),  IL /*unchanged*/ ) ]]
       <finalized-checkpoint> #Checkpoint(FinalizedEpoch, RootHash) </finalized-checkpoint>
    requires notBool ( VAL.activationEligibilityEpoch =/=K FAR_FUTURE_EPOCH
                   andBool VAL.activationEpoch >=Int computeActivationExitEpoch(FinalizedEpoch) )

  rule getActivationQueueUnsorted(.Map, IL ) => IL

  /*activation_queue = sorted([ index for ...
    ], key=lambda index: state.validator_registry[index].activation_eligibility_epoch)*/
  syntax IntList ::= sortActivationQueue( IntList ) [function]
  rule sortActivationQueue(IL) => indexForMinEligEpoch(IL) listExcept(IL, indexForMinEligEpoch(IL))
    requires IL =/=K .IntList
  rule sortActivationQueue(.IntList) => .IntList

  // min of index: state.validator_registry[index].activation_eligibility_epoch)
  syntax Int ::= indexForMinEligEpoch ( IntList )      [function, klabel(indexForMinEligEpoch)]
               | indexForMinEligEpoch ( Int, IntList ) [function, klabel(indexForMinEligEpoch2)]
  rule indexForMinEligEpoch(I:Int IL) => indexForMinEligEpoch(I, IL)
  rule [[ indexForMinEligEpoch( MIN => #if MinVAL.activationEligibilityEpoch <Int IVAL.activationEligibilityEpoch #then MIN #else I #fi,
                                (I:Int IL) => IL ) ]]
    <validators>
      MIN |-> MinVAL
      I   |-> IVAL
      ...
    </validators>
  rule indexForMinEligEpoch(MIN, .IntList) => MIN

/*
def process_slashings(state: BeaconState) -> None:
    epoch = get_current_epoch(state)
    total_balance = get_total_active_balance(state)
    for index, validator in enumerate(state.validators):
        if validator.slashed and epoch + EPOCHS_PER_SLASHINGS_VECTOR // 2 == validator.withdrawable_epoch:
            penalty = validator.effective_balance * min(sum(state.slashings) * 3, total_balance) // total_balance
            decrease_balance(state, ValidatorIndex(index), penalty)
*/
  syntax KItem ::= "processSlashings" "(" ")"
  rule <k> processSlashings() =>
           processSlashingsLoop(
             {keys_list(ValMap)}:>IntList,
             getCurrentEpoch(),
             getTotalActiveBalance()
           )
       ... </k>
       <validators> ValMap </validators>

  syntax KItem ::= "processSlashingsLoop" "(" IntList "," Int "," Int ")"
  rule <k> (. => decreaseBalance(INDEX, VAL.effectiveBalance *Int minInt(sumSlashings() *Int 3, TotalBalance) /Int TotalBalance))
           ~> processSlashingsLoop(INDEX IL => IL, EP, TotalBalance)
       ... </k>
       <validators> ... INDEX |-> VAL ... </validators>
    requires VAL.slashed andBool EP +Int EPOCHS_PER_SLASHINGS_VECTOR /Int 2 ==K VAL.withdrawableEpoch

  rule <k> processSlashingsLoop(INDEX IL => IL, EP, TotalBalance) ... </k>
       <validators> ... INDEX |-> VAL ... </validators>
    requires notBool (VAL.slashed andBool EP +Int EPOCHS_PER_SLASHINGS_VECTOR /Int 2 ==K VAL.withdrawableEpoch)

  rule <k> processSlashingsLoop(.IntList, _, _) => .K ... </k>

  syntax Int ::= sumSlashings() [function]
  rule [[ sumSlashings() => sumIntList({values(SlashMap)}:>IntList)]]
    <slashings> SlashMap </slashings>


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
  syntax KItem ::= "processFinalUpdates" "(" ")"
  rule <k> processFinalUpdates()
           => updateEffectiveBalances({keys_list(ValMap)}:>IntList, EFFECTIVE_BALANCE_INCREMENT /Int 2)             // param: HALF_INCREMENT
           ~> updateStartShard(getCurrentEpoch())                                     // param: current_epoch
           ~> setActiveIndexRoot(getCurrentEpoch() +Int 1 +Int ACTIVATION_EXIT_DELAY) // param: index_epoch
           ~> setCommitteesRoot((getCurrentEpoch() +Int 1) %Int EPOCHS_PER_HISTORICAL_VECTOR) // param: committee_root_position
           ~> resetSlashings((getCurrentEpoch() +Int 1) %Int EPOCHS_PER_SLASHINGS_VECTOR)     // param: (slashings index)
           ~> setRandaoMix((getCurrentEpoch() +Int 1) %Int EPOCHS_PER_SLASHINGS_VECTOR)       // param: (rnd mixes index)
           ~> setHistoricalRootAccumulator((getCurrentEpoch() +Int 1) %Int (SLOTS_PER_HISTORICAL_ROOT /Int SLOTS_PER_EPOCH) ==K 0)  // param: (condition)
           ~> rotateEpochAttestations() ... </k>
       <slot> SLOT </slot>
       <eth1-data-votes> E1DL => #if (SLOT +Int 1) %Int SLOTS_PER_ETH1_VOTING_PERIOD ==K 0
                                 #then .Eth1DataList
                                 #else E1DL
                                 #fi
       </eth1-data-votes>
       <validators> ValMap </validators>

  syntax KItem ::= "updateEffectiveBalances" "(" IntList "," Int ")"
  rule <k> updateEffectiveBalances(INDEX IL => IL, HALF_INCREMENT) ... </k>
       <validators> ... INDEX |-> #Validator(_,_,
                                    EffBal => minInt(BAL -Int BAL %Int EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE),
                                    _,_,_,_,_)
        ... </validators>
       <balances> ... INDEX |-> BAL ... </balances>
    requires BAL <Int EffBal orBool EffBal +Int 3 *Int HALF_INCREMENT <Int BAL

  rule <k> updateEffectiveBalances(INDEX IL => IL, HALF_INCREMENT) ... </k>
       <validators> ... INDEX |-> #Validator(_,_, EffBal, _,_,_,_,_) ... </validators>
       <balances> ... INDEX |-> BAL ... </balances>
    requires notBool(BAL <Int EffBal orBool EffBal +Int 3 *Int HALF_INCREMENT <Int BAL)

  rule <k> updateEffectiveBalances(.IntList, _) => .K ... </k>

  syntax KItem ::= "updateStartShard" "(" Int ")"
  rule <k> updateStartShard(EP) => .K ... </k>
       <start-shard> SHARD => (SHARD +Int getShardDelta(EP)) %Int SHARD_COUNT </start-shard>

  syntax KItem ::= "setActiveIndexRoot" "(" Int ")"
  rule <k> setActiveIndexRoot(IndexEpoch) => .K ... </k>
       <active-index-roots> AIR  </active-index-roots>  // TODO set active index roots properly

  syntax KItem ::= "setCommitteesRoot" "(" Int ")"
  rule <k> setCommitteesRoot(CommRootPos) => .K ... </k>
       <compact-committees-roots>
         CRS => setCommRootsAt(CommRootPos, CRS, getCompactCommitteesRoot(getCurrentEpoch() +Int 1))
       </compact-committees-roots>

  syntax BytesList ::= setCommRootsAt(Int, BytesList, Hash) [function]
  rule setCommRootsAt(Pos, CR CRS, CR') => CR setCommRootsAt(Pos -Int 1, CRS, CR') requires Pos >Int 0
  rule setCommRootsAt(0, CR CRS, CR') => CR' CRS

  syntax KItem ::= "resetSlashings" "(" Int ")"
  rule <k> resetSlashings(SlashIndex) => .K ... </k>
    <slashings> ... SlashIndex |-> (I => 0) ... </slashings>

  syntax KItem ::= "setRandaoMix" "(" Int ")"
  rule <k> setRandaoMix(RndMixIndex) => .K ... </k>
    <randao-mixes> RMS => setRandaoMixAt(
                                     RMS,
                                     RndMixIndex,
                                     "" // xor(getRandaoMix(getCurrentEpoch()), hash(R))  // TODO: this needs to be fixed
                                   )
    </randao-mixes>

  syntax KItem ::= "setHistoricalRootAccumulator" "(" Bool ")"
  rule <k> setHistoricalRootAccumulator(Condition) => .K ... </k>
    <historical-roots> HL => HL "" </historical-roots> // TODO this needs to be fixed

  syntax KItem ::= "rotateEpochAttestations" "(" ")"
  rule <k> rotateEpochAttestations() => .K ... </k>
       <previous-epoch-attestations> PEAS => CEAS </previous-epoch-attestations>
       <current-epoch-attestations> CEAS => .PendingAttestationList </current-epoch-attestations>

  // State transition function -- Block processing
  //====================================================

/*
def process_block(state: BeaconState, block: BeaconBlock) -> None:
    process_block_header(state, block)
    process_randao(state, block.body)
    process_eth1_data(state, block.body)
    process_operations(state, block.body)
*/
  syntax KItem ::= "processBlock" "(" ")"
  rule <k> processBlock() =>
                processBlockHeader()
             ~> processRandao()
             ~> processEth1Data()
             ~> process_operations()
       ... </k>

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
  syntax KItem ::= "processBlockHeader" "(" ")"
  rule <k> processBlockHeader() => .K ... </k>
       <latest-block-header>
         BHEADER  => #BeaconBlockHeader(
                       BSLOT, // block.slot
                       "", // block.parent_root // TODO needs to be PROOT
                       "",    // Hash()
                       "",    // TODO: should be hash_tree_root(block.body) ??
                       "" )    // TODO: dummy signature
       </latest-block-header>
       <slot> SLOT </slot>
       <validators> ValMap </validators>
       <blockSlot> BSLOT </blockSlot>
       <parent-root> PROOT </parent-root>
    requires BSLOT ==K SLOT
     //andBool PROOT ==K signingRoot("") // TODO: fix dummy BHEADER
     andBool notBool ({ValMap[getBeaconProposerIndex()]}:>Validator).slashed
     // TODO: not verifying signatures

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
  syntax KItem ::= "processRandao" "(" ")"
  rule <k> processRandao() => .K ... </k>
       <randao-mixes>
         RMS => setRandaoMixAt(
                  RMS,
                  getCurrentEpoch() %Int EPOCHS_PER_HISTORICAL_VECTOR,
                  "" // xor(getRandaoMix(getCurrentEpoch()), hash(R))  // TODO: this needs to be fixed
                )
       </randao-mixes>
       <randao-reveal> R </randao-reveal>
    //requires // TODO: not verifying signatures

  syntax BytesList ::= setRandaoMixAt(BytesList, Int, Hash) [function]
  rule setRandaoMixAt(RM RMS, I, RM') => RM setRandaoMixAt(RMS, I -Int 1, RM')
    requires I >Int 0
  rule setRandaoMixAt(RM RMS, 0, RM') => RM' RMS

/*
def process_eth1_data(state: BeaconState, body: BeaconBlockBody) -> None:
    state.eth1_data_votes.append(body.eth1_data)
    if state.eth1_data_votes.count(body.eth1_data) * 2 > SLOTS_PER_ETH1_VOTING_PERIOD:
        state.eth1_data = body.eth1_data
*/
  syntax KItem ::= "processEth1Data" "(" ")"
  rule <k> processEth1Data() => .K ... </k>
       <eth1-data-votes> VOTES => BlockEth1 </eth1-data-votes>
       <block-eth1-data> BlockEth1 </block-eth1-data>
     requires countEth1(VOTES BlockEth1, BlockEth1) *Int 2 >Int SLOTS_PER_ETH1_VOTING_PERIOD

  syntax KItem ::= "processEth1Data" "(" ")"
  rule <k> processEth1Data() => .K ... </k>
       <eth1-data-votes> VOTES => VOTES BlockEth1 </eth1-data-votes>
       <block-eth1-data> BlockEth1 </block-eth1-data>
     requires notBool countEth1(VOTES BlockEth1, BlockEth1) *Int 2 >Int SLOTS_PER_ETH1_VOTING_PERIOD

  syntax Int ::= countEth1(Eth1DataList, Eth1Data) [function]
  rule countEth1(E1D E1DL, E1D') => #if E1D ==K E1D'
                                    #then 1 +Int countEth1(E1DL, E1D')
                                    #else countEth1(E1DL, E1D')
                                    #fi
  rule countEth1(.Eth1DataList, E1D') => 0


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
  syntax KItem ::= "process_operations" "(" ")"
  rule <k> process_operations()
           => process_operations_aux(0, AttesterSlashings, Attestations, Deposits, VoluntaryExits, Transfers) ...</k>
    <attester-slashings> AttesterSlashings </attester-slashings>
    <attestations> Attestations </attestations>
    <deposits> Deposits </deposits>
    <voluntary-exits> VoluntaryExits </voluntary-exits>
    <transfers> Transfers </transfers>

  syntax KItem ::= "process_operations_aux" "(" proposerSlashingIndex: Int "," AttesterSlashingList "," AttestationList
                                            "," DepositList "," VoluntaryExitList "," TransferList ")"

  rule <k> (. => processProposerSlashing(ProposerSlashing))
           ~> process_operations_aux( INDEX => INDEX +Int 1, _,_,_,_,_ ) ...</k>
    <proposer-slashings>... INDEX |-> ProposerSlashing ...</proposer-slashings>

  rule <k> process_operations_aux( INDEX => -1, _,_,_,_,_ ) ...</k>
    <proposer-slashings> PSMap </proposer-slashings>
    requires notBool INDEX in keys(PSMap)

  rule (. => processAttesterSlashing(AttSlashing))
       ~> process_operations_aux(-1, AttSlashing:AttesterSlashing L => L, _,_,_,_ )
  rule (. => process_attestation(Att))
       ~> process_operations_aux(-1, .AttesterSlashingList, Att:Attestation L => L, _,_,_ )
  rule (. => process_deposit(DEP))
       ~> process_operations_aux(-1, .AttesterSlashingList, .AttestationList, DEP:Deposit L => L, _,_ )
  rule (. => process_voluntary_exit(VolEX))
       ~> process_operations_aux(-1, .AttesterSlashingList, .AttestationList, .DepositList,
                                 VolEX:VoluntaryExit L => L, _ )
  rule (. => process_transfer(TR))
       ~> process_operations_aux(-1, .AttesterSlashingList, .AttestationList, .DepositList,
                                 .VoluntaryExitList, TR:Transfer L => L )
  rule process_operations_aux(-1, .AttesterSlashingList, .AttestationList, _ .DepositList,
                              .VoluntaryExitList, .TransferList ) => .K

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
  syntax KItem ::= "processProposerSlashing" "(" ProposerSlashing ")"
  rule <k> processProposerSlashing(#ProposerSlashing(ProposerIndex, HEAD1, HEAD2)) => slashValidator(ProposerIndex, .K) ...</k>
       <validators> ProposerIndex |-> VAL ...</validators>
    requires computeEpochOfSlot(HEAD1._slot) ==Int computeEpochOfSlot(HEAD2._slot)
     andBool HEAD1 =/=K HEAD2
     andBool isSlashableValidator(VAL, getCurrentEpoch())

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
  syntax KItem ::= "processAttesterSlashing" "(" AttesterSlashing ")"
  rule processAttesterSlashing(#AttesterSlashing( IAtt1, IAtt2 ))
    => processAttesterSlashingLoop(
        sortIntList(intersection(IAtt1.custodyBit0Indices +IntList IAtt1.custodyBit1Indices,
                                 IAtt2.custodyBit0Indices +IntList IAtt2.custodyBit1Indices)), false)
    requires isSlashableAttestationData(IAtt1.data, IAtt2.data)
     andBool isValidIndexedAttestation(IAtt1)
     andBool isValidIndexedAttestation(IAtt2)

  syntax KItem ::= "processAttesterSlashingLoop" "(" IntList /*all attesting_indices*/
                                                 "," Bool /*slashed_any*/ ")"
  rule <k> (. => slashValidator(INDEX, .K))
              ~> processAttesterSlashingLoop(INDEX ILIST => ILIST, _ => true) ...</k>
    <validators> INDEX |-> VAL ...</validators>
    requires isSlashableValidator(VAL, getCurrentEpoch())

  rule <k> processAttesterSlashingLoop(INDEX ILIST => ILIST, _) ...</k>
    <validators> INDEX |-> VAL ...</validators>
    requires notBool isSlashableValidator(VAL, getCurrentEpoch())

  rule processAttesterSlashingLoop(.IntList, true) => .K
  //If 2nd arg is false, evaluation will get stuck. This corresponds to "assert slashed_any"

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
  syntax KItem ::= "process_attestation" "(" Attestation ")"
  rule <k> process_attestation( ATT )
           => process_attestation_if(ATT, #PendingAttestation(ATT.aggregation_bits,
                                                              ATT._data,
                                                              SLOT -Int getAttestationDataSlot(ATT._data),
                                                              getBeaconProposerIndex()))
       ...</k>
       <slot> SLOT </slot>
    requires ATT._data.crosslink.shard <Int SHARD_COUNT
     andBool SetItem(ATT._data.target.epoch) in SetItem(getPreviousEpoch()) SetItem(getCurrentEpoch())
     andBool getAttestationDataSlot(ATT._data) +Int MIN_ATTESTATION_INCLUSION_DELAY <=Int SLOT
     andBool SLOT <=Int getAttestationDataSlot(ATT._data) +Int SLOTS_PER_EPOCH

  //logic starting from if statement inside `process_attestation`
  syntax KItem ::= "process_attestation_if" "(" Attestation "," PendingAttestation ")"

  //if case true
  rule <k> process_attestation_if(ATT, PendingATT)
          => process_attestation_after_if(ATT, CurrentCrosslink) ...</k>
    <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
    <current-crosslinks> CurrentCrosslinkKey |-> CurrentCrosslink ...</current-crosslinks>
    <current-epoch-attestations> CurrEpochATT => CurrEpochATT PendingATT </current-epoch-attestations>
    requires ATT._data.target.epoch ==Int getCurrentEpoch() //if condition
     andBool CurrentCrosslinkKey ==Int ATT._data.crosslink.shard
     andBool ATT._data.source ==K CurrJustCHECKP

  //if case false
  rule <k> process_attestation_if(ATT, PendingATT)
          => process_attestation_after_if(ATT, PrevCrosslink) ...</k>
    <previous-justified-checkpoint> PrevJustCHECKP </previous-justified-checkpoint>
    <previous-crosslinks> PrevCrosslinkKey |-> PrevCrosslink ...</previous-crosslinks>
    <previous-epoch-attestations> PrevEpochATT => PrevEpochATT PendingATT </previous-epoch-attestations>
    requires ATT._data.target.epoch =/=Int getCurrentEpoch() //if condition
     andBool PrevCrosslinkKey ==Int ATT._data.crosslink.shard
     andBool ATT._data.source ==K PrevJustCHECKP

  //after if inside `process_attestation`
  syntax KItem ::= "process_attestation_after_if" "(" Attestation "," Crosslink ")"
  rule process_attestation_after_if(ATT, ParentCrosslink ) => .K
     //assert data.crosslink.parent_root == hash_tree_root(parent_crosslink) todo is it needed?
    requires ATT._data.crosslink.startEpoch ==Int ParentCrosslink.endEpoch
     andBool ATT._data.crosslink.endEpoch ==Int minInt(ATT._data.target.epoch, ParentCrosslink.endEpoch +Int MAX_EPOCHS_PER_CROSSLINK)
     //assert data.crosslink.data_root == Hash()
     andBool isValidIndexedAttestation(getIndexedAttestation(ATT))


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
  //todo not implemented: is_valid_merkle_branch, bls_verify
  syntax KItem ::= "process_deposit" "(" Deposit ")"

  //case pubkey in validator_pubkeys
  rule <k> process_deposit(DEP) => increaseBalance(getValidatorIndexByPubkey(DEP.data.pubkey), DEP.data.amount) ...</k>
    <eth1-deposit-index> EDI => EDI +Int 1 </eth1-deposit-index>
    requires getValidatorIndexByPubkey(DEP.data.pubkey) =/=K .ValidatorIndex

  //case pubkey not in validator_pubkeys
  rule <k> process_deposit(DEP) => .K ...</k>
    <eth1-deposit-index> EDI => EDI +Int 1 </eth1-deposit-index>
    <validators>
      VALIDATORS
      (.Map => size(VALIDATORS) |-> #Validator(DEP.data.pubkey,
                                               DEP.data.withdrawal_credentials,
                                               minInt(DEP.data.amount
                                                  -Int DEP.data.amount %Int EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE),
                                               false,
                                               FAR_FUTURE_EPOCH,
                                               FAR_FUTURE_EPOCH,
                                               FAR_FUTURE_EPOCH,
                                               FAR_FUTURE_EPOCH ) )
    </validators>
    <balances> .Map => size(VALIDATORS) |->  DEP.data.amount ...</balances>
    requires getValidatorIndexByPubkey(DEP.data.pubkey) ==K .ValidatorIndex

  syntax ValidatorIndex ::= getValidatorIndexByPubkey( BLSPubkey )                      [function]
                          | getValidatorIndexByPubkey( BLSPubkey, Map /*Validators*/ )  [function]
  rule [[ getValidatorIndexByPubkey(PUBKEY) =>  getValidatorIndexByPubkey(PUBKEY, VALIDATORS) ]]
    <validators> VALIDATORS </validators>
  rule getValidatorIndexByPubkey(PUBKEY, _:Map (I |-> VAL:Validator => .Map))
    requires VAL.pubkey =/=K PUBKEY
  rule getValidatorIndexByPubkey(PUBKEY, _:Map (I |-> VAL:Validator)) => I
    requires VAL.pubkey ==K PUBKEY
  rule getValidatorIndexByPubkey(_, .Map) => .ValidatorIndex


/*
def process_voluntary_exit(state: BeaconState, exit: VoluntaryExit) -> None:
    validator = state.validators[exit.validator_index]
    # Verify the validator is active
    assert is_active_validator(validator, get_current_epoch(state))
    # Verify the validator has not yet exited
    assert validator.exit_epoch == FAR_FUTURE_EPOCH
    # Exits must specify an epoch requires they become valid; they are not valid before then
    assert get_current_epoch(state) >= exit.epoch
    # Verify the validator has been active long enough
    assert get_current_epoch(state) >= validator.activation_epoch + PERSISTENT_COMMITTEE_PERIOD
    # Verify signature
    domain = get_domain(state, DOMAIN_VOLUNTARY_EXIT, exit.epoch)
    assert bls_verify(validator.pubkey, signing_root(exit), exit.signature, domain)
    # Initiate exit
    initiate_validator_exit(state, exit.validator_index)
*/
  syntax KItem ::= "process_voluntary_exit" "(" VoluntaryExit ")"

  rule <k> process_voluntary_exit(#VoluntaryExit(ExitEPOCH, ValINDEX, _)) => initiateValidatorExit(ValINDEX) ...</k>
       <validators> ValINDEX |-> VAL ...</validators>
    requires isActiveValidator(VAL, getCurrentEpoch())
     andBool VAL.exitEpoch ==Int FAR_FUTURE_EPOCH
     andBool getCurrentEpoch() >=Int ExitEPOCH
     andBool getCurrentEpoch() >=Int VAL.activationEpoch +Int PERSISTENT_COMMITTEE_PERIOD

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
  syntax KItem ::= "process_transfer" "(" Transfer ")"

  rule <k> process_transfer(#Transfer( SENDER, RECIPIENT, AMOUNT, FEE, TrSLOT, PUBKEY, SIGNATURE ))
           => decreaseBalance(SENDER, AMOUNT +Int FEE)
           ~> increaseBalance(RECIPIENT, AMOUNT)
           ~> increaseBalance(getBeaconProposerIndex(), FEE)
           ~> process_transfer_post_assert(SENDER, RECIPIENT) //last 2 asserts
       ...</k>
       <slot> SLOT </slot>
       <validators> SENDER |-> SenderVAL ...</validators>
    requires getBalance(SENDER) >=Int maxInt(AMOUNT +Int FEE, maxInt(AMOUNT, FEE))
     andBool SLOT ==Int TrSLOT
     andBool (
               SenderVAL.activationEligibilityEpoch ==Int FAR_FUTURE_EPOCH
        orBool getCurrentEpoch() >=Int SenderVAL.withdrawableEpoch
        orBool getBalance(SENDER) >=Int AMOUNT +Int FEE +Int MAX_EFFECTIVE_BALANCE
      )
      //todo needs hash() first
      //assert state.validators[transfer.sender].withdrawal_credentials == BLS_WITHDRAWAL_PREFIX + hash(transfer.pubkey)[1:]
      //assert bls_verify(transfer.pubkey, signing_root(transfer), transfer.signature, get_domain(state, DOMAIN_TRANSFER))

  syntax KItem ::= "process_transfer_post_assert" "(" ValidatorIndex "," ValidatorIndex ")"
  rule process_transfer_post_assert(SENDER, RECIPIENT) => .K
    requires notBool (0 <Int getBalance(SENDER)    andBool    getBalance(SENDER) <Int MIN_DEPOSIT_AMOUNT)
     andBool notBool (0 <Int getBalance(RECIPIENT) andBool getBalance(RECIPIENT) <Int MIN_DEPOSIT_AMOUNT)

  syntax Int ::= getBalance( ValidatorIndex ) [function]
  rule [[ getBalance(INDEX) => BAL ]]
    <balances> INDEX |-> BAL ...</balances>

endmodule
