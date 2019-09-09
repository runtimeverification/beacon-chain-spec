/*
 * Notes:
 *   - bls_verify is not implemented (as discussed). Signature verification is not done.
 */

requires "hash-tree.k"

module BEACON-CHAIN
  imports DOMAINS
  imports HASH-TREE

  // Hacks around pyk/json front-end limitations
  //====================================================

  //Workarounds to make kast happy. Cannot put a function with no-args in init <k>, with json input.
  syntax KItem ::= "wrap_hash_tree_root" "(" BytesOrContainer ")" [klabel(wrap_hash_tree_root), symbol]
                 | "wrap_hash_tree_root_block" "(" ")" [klabel(wrap_hash_tree_root_block), symbol]
                 | "wrap_hash_tree_root_blockBody" "(" ")" [klabel(wrap_hash_tree_root_blockBody), symbol]
                 | "wrap_hash_tree_root_state" "(" ")" [klabel(wrap_hash_tree_root_state), symbol]
  rule wrap_hash_tree_root(OBJ) => hash_tree_root(OBJ)
  rule wrap_hash_tree_root_block() => hash_tree_root_block()
  rule wrap_hash_tree_root_blockBody() => hash_tree_root_blockBody()
  rule wrap_hash_tree_root_state() => hash_tree_root_state()


  // Initialization
  //====================================================
  syntax KItem ::= "init"                                 [klabel(init), symbol]
                 | initZeroHashes(Int, Int)

/*
ZERO_BYTES32 = b'\x00' * 32

zerohashes = [ZERO_BYTES32]
for layer in range(1, 100):
    zerohashes.append(hash(zerohashes[layer - 1] + zerohashes[layer - 1]))
*/
  rule <k> init => initZeroHashes(1, 64) ...</k> //max pre-computed zerohash is 64 - ehough for all cases
       <zerohashes-cache> .Map => (0 |-> defaultHash()) </zerohashes-cache>

  rule <k> initZeroHashes(I => I +Int 1, N) ...</k>
       <zerohashes-cache> (.Map => (I |-> hashConcat(zerohashes(I -Int 1), zerohashes(I -Int 1)))) ...</zerohashes-cache>
    requires I <Int N

  rule initZeroHashes(N, N) => .K


  // Helper functions -- Math
  //====================================================

/*
def integer_squareroot(n: uint64) -> uint64:
    """
    Return the largest integer ``x`` such that ``x**2 <= n``.
    """
    x = n
    y = (x + 1) // 2
    while y < x:
        x = y
        y = (x + n // x) // 2
    return x
*/
  syntax Int ::= "integer_squareroot" "(" Int ")" [function]
  rule integer_squareroot(N) => integer_squareroot_aux(N, N, (N +Int 1) /Int 2)
    requires N >=Int 0

  syntax Int ::= "integer_squareroot_aux" "(" Int "," Int "," Int ")" [function]
  rule integer_squareroot_aux(N, X => Y, Y => (Y +Int N /Int Y) /Int 2)
    requires Y <Int X
  rule integer_squareroot_aux(N, X, Y) => X
    requires Y >=Int X

/*
def xor(bytes_1: Bytes32, bytes_2: Bytes32) -> Bytes32:
    """
    Return the exclusive-or of two 32-byte strings.
    """
    return Bytes32(a ^ b for a, b in zip(bytes_1, bytes_2))
*/
  syntax Bytes ::= xor( Bytes, Bytes ) [function]
  rule xor(A, B) => chrChar(ordChar(substrString(A, 0, 1)) ^Int ordChar(substrString(B, 0, 1)))
                    +Bytes xor(substrString(A, 1, lengthString(A) -Int 1), substrString(B, 1, lengthString(B) -Int 1))
    requires lengthString(A) >Int 0 andBool lengthString(B) >Int 0
  rule xor("", "") => ""


  // Helper functions -- Predicates
  //====================================================
/*
def is_active_validator(validator: Validator, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is active.
    """
    return validator.activation_epoch <= epoch < validator.exit_epoch
*/
  syntax Bool ::= "is_active_validator" "(" Validator "," Int ")" [function]
  rule is_active_validator( VAL, EPOCH )
    => VAL.activationEpoch <=Int EPOCH andBool EPOCH <Int VAL.exitEpoch

/*
def is_slashable_validator(validator: Validator, epoch: Epoch) -> bool:
    """
    Check if ``validator`` is slashable.
    """
    return (not validator.slashed) and (validator.activation_epoch <= epoch < validator.withdrawable_epoch)
*/
  syntax Bool ::= "is_slashable_validator" "(" Validator "," Int ")" [function]
  rule is_slashable_validator( VAL, EPOCH )
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
  syntax Bool ::= "is_slashable_attestation_data" "(" AttestationData "," AttestationData ")" [function]
  rule is_slashable_attestation_data(
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
    Check if ``indexed_attestation`` has valid indices and signature.
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
  syntax Bool ::= "is_valid_indexed_attestation" "(" IndexedAttestation ")" [function]
  rule is_valid_indexed_attestation(IAtt)
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
  syntax Bool ::= "is_valid_merkle_branch" "(" Hash "," BytesList "," Int "," Int "," Hash ")" [function]
  rule is_valid_merkle_branch(Leaf, Branch, Depth, Index, Root)
       => is_valid_merkle_branch_aux(Branch, Depth, Index, Root, 0, Leaf)

  syntax Bool ::= "is_valid_merkle_branch_aux" "(" BytesList "," Int "," Int "," Hash "," Int "," Hash ")" [function]
  rule is_valid_merkle_branch_aux(Branch, Depth, Index, _,
                                  I => I +Int 1,
                                  Value => #if Index /Int (2 ^Int I) %Int 2 ==K 1
                                           #then {hash(Branch[I] +Bytes Value)}:>Hash
                                           #else {hash(Value +Bytes Branch[I])}:>Hash
                                           #fi
                                 )
    requires I <Int Depth

  rule is_valid_merkle_branch_aux(_, Depth, _, Root, I, Value) => Root ==String Value
    requires I >=Int Depth

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
  syntax Int ::= "compute_shuffled_index" "(" Int "," Int "," Hash ")" [function]
  rule compute_shuffled_index(INDEX, COUNT, SEED) => compute_shuffled_index_loop(INDEX, COUNT, SEED, 0, SHUFFLE_ROUND_COUNT)

  syntax Int ::= "compute_shuffled_index_loop" "(" Int "," Int "," Hash "," Int "," Int ")" [function]
  rule compute_shuffled_index_loop(
         INDEX => #if computeBit(maxInt(INDEX, computeFlip(computePivot(SEED, CurrRound, COUNT), INDEX, COUNT)),
                                 SEED, CurrRound)
                  #then computeFlip(computePivot(SEED, CurrRound, COUNT), INDEX, COUNT)
                  #else INDEX
                  #fi,
         COUNT,
         SEED,
         CurrRound => CurrRound +Int 1,
         RoundCount
    )
    requires CurrRound <Int RoundCount

  rule compute_shuffled_index_loop(INDEX, _, _, CurrRound, RoundCount) => INDEX
    requires CurrRound >=Int RoundCount

//        byte = source[(position % 256) // 8]
//        bit = (byte >> (position % 8)) % 2
  syntax Bool ::= computeBit(Int /* position */, Hash /* seed */, Int /* current round */ ) [function]
  rule computeBit(Position, Seed, CurrRound)
    => (ordChar( substrString({computeSource(Position, Seed, CurrRound)}:>String,
                      (Position %Int 256) /Int 8,
                      (Position %Int 256) /Int 8 +Int 1)
       ) /Int 2 ^Int (Position %Int 8))  // shifting right by (position % 8)
       %Int 2 ==Int 1

  syntax Hash ::= computeSource(Int /* position */, Hash /* seed */, Int /* current round */) [function]
  rule computeSource(Position, Seed, CurrRound)
    => hash(({Seed}:>Bytes +Bytes to_bytes(CurrRound, 1)) +Bytes to_bytes(Position /Int 256, 4))

  syntax Int ::= computeFlip(Int /* pivot */, Int /* index */, Int /* count */ ) [function]
  rule computeFlip(Pivot, Index, Count) => (Pivot +Int Count -Int Index) %Int Count

  //pivot = bytes_to_int(hash(seed + int_to_bytes(current_round, length=1))[0:8]) % index_count
  syntax Int ::= computePivot(Hash /* seed */, Int /* current round */, Int /* index count */ ) [function]
    rule computePivot(Seed, CurrRound, Count)
      => bytes_to_int(substrString({hash({Seed}:>Bytes +Bytes to_bytes(CurrRound, 1))}:>String, 0, 8)) %Int Count

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
  syntax IntList ::= "compute_committee" "(" IntList "," Hash "," Int "," Int ")" [function]
  rule compute_committee(INDICES, SEED, INDEX, COUNT)
    => computeCommitteeLoop(
        (len(INDICES) *Int INDEX) /Int COUNT,
        (len(INDICES) *Int (INDEX +Int 1)) /Int COUNT,
        SEED,
        INDICES,
        .IntList
    )

  syntax IntList ::= computeCommitteeLoop( Int, Int, Hash, IntList, IntList )     [function]
  rule computeCommitteeLoop(I => I +Int 1, END, SEED, INDICES,
                            RESULT => RESULT +append INDICES[compute_shuffled_index(I, len(INDICES), SEED)] )
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
  syntax Int ::= "compute_epoch_of_slot" "(" Int ")" [function]
  rule compute_epoch_of_slot(SLOT) => SLOT /Int SLOTS_PER_EPOCH

/*
def compute_start_slot_of_epoch(epoch: Epoch) -> Slot:
    """
    Return the start slot of ``epoch``.
    """
    return Slot(epoch * SLOTS_PER_EPOCH)
*/
  syntax Int ::= "compute_start_slot_of_epoch" "(" Int ")" [function]
  rule compute_start_slot_of_epoch(EPOCH) => EPOCH *Int SLOTS_PER_EPOCH

/*
def compute_activation_exit_epoch(epoch: Epoch) -> Epoch:
    """
    Return the epoch during which validator activations and exits initiated in ``epoch`` take effect.
    """
    return Epoch(epoch + 1 + ACTIVATION_EXIT_DELAY)
*/
  syntax Int ::= "compute_activation_exit_epoch" "(" Int ")" [function]
  rule compute_activation_exit_epoch(EP) => EP +Int 1 +Int ACTIVATION_EXIT_DELAY

/*
def compute_domain(domain_type: DomainType, fork_version: Version=Version()) -> Domain:
    """
    Return the domain for the ``domain_type`` and ``fork_version``.
    """
    return Domain(domain_type + fork_version)
*/
  syntax Domain ::= "compute_domain" "(" DomainType "," Version ")"    [function]
  rule compute_domain(Domain_Type, Fork_Version) => Domain_Type +Bytes Fork_Version

  // Helper functions -- Beacon state accessors
  //====================================================

/*
def get_current_epoch(state: BeaconState) -> Epoch:
    """
    Return the current epoch.
    """
    return compute_epoch_of_slot(state.slot)
*/
  syntax Int ::= "get_current_epoch" "(" ")" [function]
  rule [[ get_current_epoch() => compute_epoch_of_slot(SLOT) ]]
    <slot> SLOT </slot>

/*
def get_previous_epoch(state: BeaconState) -> Epoch:
    """`
    Return the previous epoch (unless the current epoch is ``GENESIS_EPOCH``).
    """
    current_epoch = get_current_epoch(state)
    return GENESIS_EPOCH if current_epoch == GENESIS_EPOCH else Epoch(current_epoch - 1)
*/
  syntax Int ::= "get_previous_epoch" "(" ")" [function]
  rule get_previous_epoch() =>  #if get_current_epoch() ==K GENESIS_EPOCH
                                #then GENESIS_EPOCH
                                #else get_current_epoch() -Int 1
                                #fi

/*
def get_block_root(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the block root at the start of a recent ``epoch``.
    """
    return get_block_root_at_slot(state, compute_start_slot_of_epoch(epoch))
*/
  syntax Hash ::= "get_block_root" "(" Int ")" [function]
  rule get_block_root(EP) => get_block_root_at_slot(compute_start_slot_of_epoch(EP))

/*
def get_block_root_at_slot(state: BeaconState, slot: Slot) -> Hash:
    """
    Return the block root at a recent ``slot``.
    """
    assert slot < state.slot <= slot + SLOTS_PER_HISTORICAL_ROOT
    return state.block_roots[slot % SLOTS_PER_HISTORICAL_ROOT]
*/
  syntax Hash ::= "get_block_root_at_slot" "(" Int ")" [function]
  rule [[ get_block_root_at_slot(SLOT) => {BLOCKROOTS[ SLOT %Int SLOTS_PER_HISTORICAL_ROOT ]}:>Hash ]]
    <slot> StateSLOT </slot>
    <block-roots> BLOCKROOTS </block-roots>
    requires SLOT <Int StateSLOT andBool StateSLOT <=Int (SLOT +Int SLOTS_PER_HISTORICAL_ROOT)

/*
def get_randao_mix(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the randao mix at a recent ``epoch``.
    """
    return state.randao_mixes[epoch % EPOCHS_PER_HISTORICAL_VECTOR]
*/
  syntax Hash ::= "get_randao_mix" "(" Int ")" [function]
  rule [[ get_randao_mix( EPOCH ) => {RMS[ EPOCH %Int EPOCHS_PER_HISTORICAL_VECTOR ]}:>Hash ]]
    <randao-mixes> RMS </randao-mixes>

/*
def get_active_validator_indices(state: BeaconState, epoch: Epoch) -> Sequence[ValidatorIndex]:
    """
    Return the sequence of active validator indices at ``epoch``.
    """
    return [ValidatorIndex(i) for i, v in enumerate(state.validators) if is_active_validator(v, epoch)]
*/
  syntax IntList ::= "get_active_validator_indices" "(" epoch: Int ")" [function]
  rule [[ get_active_validator_indices(EP) => getActiveValidatorIndicesAux(.IntList, 0, VALIDATORS, EP) ]]
    <validators> VALIDATORS </validators>

  syntax IntList ::= getActiveValidatorIndicesAux( result: IntList, i: Int, validators: Map, epoch: Int ) [function]
  rule getActiveValidatorIndicesAux(_,          I => I +Int 1, _:Map (I |-> V => .Map), EP )
    requires notBool is_active_validator(V, EP)
  rule getActiveValidatorIndicesAux(Is => Is +append I, I => I +Int 1, _:Map (I |-> V => .Map), EP )
    requires         is_active_validator(V, EP)
  rule getActiveValidatorIndicesAux(Is, _, .Map, _) => Is

/*
def get_validator_churn_limit(state: BeaconState) -> uint64:
    """
    Return the validator churn limit for the current epoch.
    """
    active_validator_indices = get_active_validator_indices(state, get_current_epoch(state))
    return max(MIN_PER_EPOCH_CHURN_LIMIT, len(active_validator_indices) // CHURN_LIMIT_QUOTIENT)
*/
  syntax Int ::= "get_validator_churn_limit" "(" ")" [function]
  rule get_validator_churn_limit() => maxInt(
          MIN_PER_EPOCH_CHURN_LIMIT,
          len(get_active_validator_indices(get_current_epoch())) /Int CHURN_LIMIT_QUOTIENT )

/*
def get_seed(state: BeaconState, epoch: Epoch) -> Hash:
    """
    Return the seed at ``epoch``.
    """
    mix = get_randao_mix(state, Epoch(epoch + EPOCHS_PER_HISTORICAL_VECTOR - MIN_SEED_LOOKAHEAD - 1))  # Avoid underflow
    active_index_root = state.active_index_roots[epoch % EPOCHS_PER_HISTORICAL_VECTOR]
    return hash(mix + active_index_root + int_to_bytes(epoch, length=32))
*/
  syntax Hash ::= "get_seed" "(" Int ")" [function]
  rule [[ get_seed(Epoch)
    => hash( get_randao_mix(Epoch +Int EPOCHS_PER_HISTORICAL_VECTOR -Int MIN_SEED_LOOKAHEAD -Int 1)
             +Bytes (ActiveIndexRoots[Epoch %Int EPOCHS_PER_HISTORICAL_VECTOR]
             +Bytes to_bytes(Epoch, 32))
           ) ]]
    <active-index-roots> ActiveIndexRoots </active-index-roots>

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
  syntax Int ::= "get_committee_count" "(" Int ")" [function]
  rule get_committee_count( EP )
    => maxInt(1, minInt(SHARD_COUNT /Int SLOTS_PER_EPOCH,
                        len(get_active_validator_indices(EP)) /Int SLOTS_PER_EPOCH /Int TARGET_COMMITTEE_SIZE
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
  syntax IntList ::= "get_crosslink_committee" "(" Int "," Int ")" [function]
  rule get_crosslink_committee(EPOCH, SHARD)
    => compute_committee(
          get_active_validator_indices(EPOCH),
          get_seed(EPOCH),
          (SHARD +Int SHARD_COUNT -Int get_start_shard(EPOCH)) %Int SHARD_COUNT,
          get_committee_count(EPOCH)
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
  syntax Int ::= "get_start_shard" "(" Int ")" [function]
  rule [[ get_start_shard(EPOCH) => getStartShardAux(
      get_current_epoch() +Int 1,
      (LSS +Int get_shard_delta(get_current_epoch())) %Int SHARD_COUNT,
      EPOCH
    ) ]]
    <start-shard> LSS </start-shard>
    requires EPOCH <=Int get_current_epoch() +Int 1

  syntax Int ::= getStartShardAux( Int, Int, Int ) [function]
  rule getStartShardAux(
      CheckEP => CheckEP -Int 1,
      SHARD => (SHARD +Int SHARD_COUNT -Int get_shard_delta(CheckEP -Int 1)) %Int SHARD_COUNT,
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
  syntax Int ::= "get_shard_delta" "(" Int ")" [function]
  rule get_shard_delta( EPOCH ) => minInt(
    get_committee_count(EPOCH),
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
  syntax ValidatorIndex ::= "get_beacon_proposer_index" "(" ")" [function]
  rule [[ get_beacon_proposer_index()
       => #fun(EPOCH
       => #fun(CommitteesPerSlot
       => #fun(OFFSET
       => #fun(SHARD
       => #fun(FirstCommittee
       => #fun(MaxRandomByte
       => #fun(SEED
       => #fun(I
       => getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD,
                                     FirstCommittee, MaxRandomByte, SEED, I)
          )(0)
          )(get_seed(EPOCH))
          )(2 ^Int 8 -Int 1)
          )(get_crosslink_committee(EPOCH, SHARD))
          )((get_start_shard(EPOCH) +Int OFFSET) %Int SHARD_COUNT)
          )(CommitteesPerSlot *Int (SLOT %Int SLOTS_PER_EPOCH))
          )(get_committee_count(EPOCH) /Int SLOTS_PER_EPOCH)
          )(get_current_epoch())
       ]]
    <slot> SLOT </slot>

/*  i = 0
    while True:
        candidate_index = first_committee[(epoch + i) % len(first_committee)]
        random_byte = hash(seed + int_to_bytes(i // 32, length=8))[i % 32]
        effective_balance = state.validators[candidate_index].effective_balance
        if effective_balance * MAX_RANDOM_BYTE >= MAX_EFFECTIVE_BALANCE * random_byte:
            return ValidatorIndex(candidate_index)
        i += 1  */
  syntax ValidatorIndex ::= getBeaconProposerIndexLoop(
                              Int, Int, Int, Int, IntList, Int, Hash, Int) [function]
  rule getBeaconProposerIndexLoop(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I)
       => #fun(CandidateIndex
       => #fun(RandomByte
       => #fun(EffectiveBalance
       => getBeaconProposerIndexLoopAux(EPOCH, CommitteesPerSlot, OFFSET, SHARD, FirstCommittee, MaxRandomByte, SEED, I,
                                        CandidateIndex, RandomByte, EffectiveBalance )
          )(getValidator(CandidateIndex).effectiveBalance)
          //random_byte = hash(seed + int_to_bytes(i // 32, length=8))[i % 32]
          )(getByte( hashConcat(SEED, to_bytes(I /Int 32, 8) ), I %Int 32))
          )(FirstCommittee[(EPOCH +Int I) %Int len(FirstCommittee)])

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
    syntax Int ::= "get_attestation_data_slot" "(" AttestationData ")" [function]
    rule get_attestation_data_slot(#AttestationData(_,_, #Checkpoint(EP,_), #Crosslink(SHARD,_,_,_,_))) =>
      compute_start_slot_of_epoch(EP) +Int
        // offset
        (( SHARD +Int SHARD_COUNT -Int get_start_shard(EP) ) %Int SHARD_COUNT) /Int
        // (committee_count // SLOTS_PER_EPOCH)
        (get_committee_count(EP) /Int SLOTS_PER_EPOCH)

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
  syntax Hash ::= "get_compact_committees_root" "(" Int ")" [function]
  rule get_compact_committees_root(EPOCH)
      //Vector[CompactCommittee, SHARD_COUNT]
    => hash_tree_root_list(
         computeCompactCommitteesComLoop(
           EPOCH, get_start_shard(EPOCH), 0, get_committee_count(EPOCH), initCompCommListOfSize(SHARD_COUNT)),
           SHARD_COUNT,
           %container,
           true)

  syntax CompactCommitteeList ::= computeCompactCommitteesComLoop(Int, Int, Int, Int, CompactCommitteeList) [function]
  rule computeCompactCommitteesComLoop(
         Epoch, StartShard,
         CommNum => CommNum +Int 1,
         CommCount,
         CommitteeList => computeCompactCommitteesIndLoop(
                            (StartShard +Int CommNum) %Int SHARD_COUNT,
                            get_crosslink_committee(Epoch, (StartShard +Int CommNum) %Int SHARD_COUNT),
                            CommitteeList))
    requires CommNum <Int CommCount

  rule computeCompactCommitteesComLoop(_,_, CommNum, CommCount, CommitteeList) => CommitteeList
    requires CommNum >=Int CommCount

  syntax CompactCommitteeList ::=computeCompactCommitteesIndLoop(Int, IntList, CompactCommitteeList) [function]
  rule computeCompactCommitteesIndLoop(
            Shard,
            I IL => IL,
            CommitteeList => setCommAtShard(CommitteeList,
                                            Shard,
                                            updateCompComm(CommitteeList[Shard],
                                                           getValidator(I).pubkey,
                                                           computeCompactValidatorIndex(
                                                             I,
                                                             #if getValidator(I).slashed #then 1 #else 0 #fi,
                                                             getValidator(I).effectiveBalance /Int EFFECTIVE_BALANCE_INCREMENT))))

  rule computeCompactCommitteesIndLoop(_, .IntList, CommitteeList) => CommitteeList

  syntax Int ::= computeCompactValidatorIndex(Int, Int, Int)  [function]
  rule computeCompactValidatorIndex(I, Slashed, CompBal)
    => (I *Int (2 ^Int 16)) +Int (Slashed *Int (2 ^Int 15)) +Int CompBal

  syntax CompactCommittee ::= updateCompComm(CompactCommittee, BLSPubkey, Int) [function]
  rule updateCompComm(#CompactCommittee(PKS, IL), PK, I) => #CompactCommittee(PKS +append PK, IL +append I)

  syntax CompactCommitteeList ::= setCommAtShard(CompactCommitteeList, Int, CompactCommittee) [function]
  rule setCommAtShard(C CL, SHARD, C') => C setCommAtShard(CL, SHARD -Int 1, C')
    requires SHARD >Int 0
  rule setCommAtShard(C CL, 0, C') => C' CL

/*
def get_total_balance(state: BeaconState, indices: Set[ValidatorIndex]) -> Gwei:
    """
    Return the combined effective balance of the ``indices``. (1 Gwei minimum to avoid divisions by zero.)
    """
    return Gwei(max(1, sum([state.validators[index].effective_balance for index in indices])))
*/
  syntax Int ::= "get_total_balance" "(" IntList ")" [function]
  rule get_total_balance(INDICES) => maxInt(1, getTotalBalancePure(INDICES, 0))

  syntax Int ::= getTotalBalancePure( IntList, Int ) [function]
  rule getTotalBalancePure(I IL => IL, S => S +Int getValidator(I).effectiveBalance)
  rule getTotalBalancePure(.IntList, S) => S

/*
def get_total_active_balance(state: BeaconState) -> Gwei:
    """
    Return the combined effective balance of the active validators.
    """
    return get_total_balance(state, set(get_active_validator_indices(state, get_current_epoch(state))))
*/
  syntax Int ::= "get_total_active_balance" "(" ")" [function]
  rule get_total_active_balance() => get_total_balance(get_active_validator_indices(get_current_epoch()))

/*
def get_domain(state: BeaconState, domain_type: DomainType, message_epoch: Epoch=None) -> Domain:
    """
    Return the signature domain (fork version concatenated with domain type) of a message.
    """
    epoch = get_current_epoch(state) if message_epoch is None else message_epoch
    fork_version = state.fork.previous_version if epoch < state.fork.epoch else state.fork.current_version
    return compute_domain(domain_type, fork_version)
*/
  syntax Domain ::= "get_domain" "(" DomainType "," OptionInt ")" [function]
  rule get_domain(DTYPE, OEPOCH)
    => get_domain_aux(DTYPE, #if isNone(OEPOCH) #then get_current_epoch() #else intOf(OEPOCH) #fi)

  syntax Domain ::= "get_domain_aux" "(" DomainType "," Int ")" [function]
  rule [[ get_domain_aux(DTYPE, EPOCH)
    => compute_domain(DTYPE, #if EPOCH <Int FEPOCH #then FPREV #else FCURR #fi) ]]
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
  syntax IndexedAttestation ::= "get_indexed_attestation" "(" Attestation ")" [function]
  rule get_indexed_attestation(#Attestation(AggregationBits, DATA, CustodyBits, SIG)) =>
    #fun(AttestingIndices =>
    #fun(CustodyBit1Indices =>
    #fun(CustodyBit0Indices => #IndexedAttestation(
                                  sortIntList(CustodyBit0Indices),
                                  sortIntList(CustodyBit1Indices),
                                  DATA,
                                  SIG
                               )
    )(listDiff(AttestingIndices, CustodyBit1Indices))
    )(get_attesting_indices(DATA, CustodyBits))
    )(get_attesting_indices(DATA, AggregationBits))
    // assert custody_bit_1_indices.issubset(attesting_indices)
    //requires listDiff(CustodyBit1Indices, AttestingIndices) ==K .IntList - cannot be used, vars out of scope
    requires listDiff(get_attesting_indices(DATA, CustodyBits), get_attesting_indices(DATA, AggregationBits)) ==K .IntList

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
  syntax IntList ::= "get_attesting_indices" "(" AttestationData "," BitList ")" [function]
  rule get_attesting_indices(#AttestationData(_,_, #Checkpoint(EP,_), #Crosslink(SHARD,_,_,_,_)), BL) =>
    extractAttestingIndices(get_crosslink_committee(EP, SHARD), BL, .IntList)

  syntax IntList ::= extractAttestingIndices(IntList, BitList, IntList) [function]
  rule extractAttestingIndices(I IL => IL, true  BL => BL, AL => AL +append I)
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
  syntax KItem ::= "increase_balance" "(" ValidatorIndex "," Int ")"
  rule <k> increase_balance(ValIndex, Delta) => . ...</k>
       <balances>... ValIndex |-> (BAL => BAL +Int Delta) ...</balances>

/*
def decrease_balance(state: BeaconState, index: ValidatorIndex, delta: Gwei) -> None:
    """
    Decrease the validator balance at index ``index`` by ``delta``, with underflow protection.
    """
    state.balances[index] = 0 if delta > state.balances[index] else state.balances[index] - delta
*/
  syntax KItem ::= "decrease_balance" "(" ValidatorIndex "," Int ")"
  rule <k> decrease_balance(ValIndex, Delta) => . ...</k>
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
  syntax KItem ::= "initiate_validator_exit" "(" Int ")"
                 | initiateValidatorExitAux( Int /*index*/ , Int /*exit_queue_epoch*/ )

  rule initiate_validator_exit(INDEX) => .K
    requires getValidator(INDEX).exitEpoch =/=K FAR_FUTURE_EPOCH

  rule initiate_validator_exit(INDEX) => initiateValidatorExitAux(INDEX, exitQueueEpochAux(INDEX))
    requires getValidator(INDEX).exitEpoch ==K FAR_FUTURE_EPOCH

  rule <k> initiateValidatorExitAux(INDEX, ExitQEpoch) => .K ...</k>
       <validators>
       VALIDATORS:Map
       INDEX |-> #Validator(_,_,_,_,_,_,
            ExitEPOCH => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int get_validator_churn_limit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi ,
            WithdrEpoch => #if exitQueueChurnAux(ExitQEpoch, VALIDATORS, 0) >=Int get_validator_churn_limit()
                            #then ExitQEpoch +Int 1
                            #else ExitQEpoch
                         #fi +Int MIN_VALIDATOR_WITHDRAWABILITY_DELAY)
       </validators>

  syntax Int ::= exitQueueEpochAux ( Int ) [function]
  rule [[ exitQueueEpochAux(INDEX)
          => maxAux(compute_activation_exit_epoch(get_current_epoch())
                    exitEpochsAux(VALIDATORS, .IntList) ) ]]
    <validators> VALIDATORS </validators>

  syntax IntList ::= exitEpochsAux( Map /*validators*/ , IntList /*result*/ ) [function]
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
  syntax KItem ::= "slash_validator" "(" ValidatorIndex "," /*slashed_index*/
                                         ValidatorIndex     /*whistleblower_index or .ValidatorIndex if none*/ ")"

    rule <k> slash_validator(SlashedINDEX, WhistleblINDEX)
             => initiate_validator_exit(SlashedINDEX)
             ~> slashValidatorAux(SlashedINDEX,
                                  #if WhistleblINDEX ==K .ValidatorIndex #then get_beacon_proposer_index() #else WhistleblINDEX #fi,
                                  get_beacon_proposer_index(),
                                  VAL.effectiveBalance /Int WHISTLEBLOWER_REWARD_QUOTIENT, //whistleblower_reward
                                  VAL.effectiveBalance /Int WHISTLEBLOWER_REWARD_QUOTIENT /Int PROPOSER_REWARD_QUOTIENT, //proposer_reward
                                  get_current_epoch()) //epoch
          ...</k>
         <validators> SlashedINDEX |-> VAL ...</validators>

 syntax KItem ::= "slashValidatorAux" "(" ValidatorIndex "," ValidatorIndex "," ValidatorIndex "," Int "," Int "," Int ")"
    rule <k> slashValidatorAux(SlashedINDEX, WhistleblINDEX, ProposerINDEX, WhistleREWARD, ProposerREWARD, Epoch)
         => decrease_balance(SlashedINDEX, EffBALANCE /Int MIN_SLASHING_PENALTY_QUOTIENT)
         ~> increase_balance(ProposerINDEX, ProposerREWARD)
         ~> increase_balance(WhistleblINDEX, WhistleREWARD -Int ProposerREWARD)
         ...</k>
      <validators>
        SlashedINDEX |-> #Validator(
          _,_,
          EffBALANCE,
          _ => true, //slashed
          _,_,_,
          WithdEPOCH => maxInt(WithdEPOCH, Epoch +Int EPOCHS_PER_SLASHINGS_VECTOR) //withdrawable epoch
        )
        ...
      </validators>
      <slashings> Epoch %Int EPOCHS_PER_SLASHINGS_VECTOR |-> (SL => SL +Int EffBALANCE)  ...</slashings>

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
  syntax KItem ::= "initialize_beacon_state_from_eth1" "(" Hash "," Int "," DepositList ")"
  rule <k> initialize_beacon_state_from_eth1(E1BH, E1TS, Deposits)
           => processEth1Deposits(Deposits, getDataList(Deposits), 0)
           ~> processEth1Activations(size(ValMap), 0)
           ~> populateEth1Roots(
                // List[ValidatorIndex, VALIDATOR_REGISTRY_LIMIT]
                hash_tree_root_list(get_active_validator_indices(GENESIS_EPOCH), VALIDATOR_REGISTRY_LIMIT, %uint64, false),
                get_compact_committees_root(GENESIS_EPOCH),
                0, EPOCHS_PER_HISTORICAL_VECTOR)
       ... </k>
       <genesis-time> _ => E1TS -Int E1TS %Int SECONDS_PER_DAY +Int 2 *Int SECONDS_PER_DAY </genesis-time>
       <eth1-data> _ => #Eth1Data("", len(Deposits), E1BH) </eth1-data>  // deposit root unspecified, hence the ""
       <latest-block-header>
              //BeaconBlockHeader(body_root=hash_tree_root(BeaconBlockBody()))
         _ => #BeaconBlockHeader(0, defaultHash(), defaultHash(), hash_tree_root_blockBodyEmpty(), defaultBytes96())
       </latest-block-header>
       <validators> ValMap </validators>

  syntax KItem ::= "processEth1Deposits" "(" DepositList "," DepositDataList "," Int ")"
  rule <k> (. => process_deposit(Dep))
           ~> processEth1Deposits(Dep Deposits => Deposits, Leaf Leaves => Leaves, INDEX => INDEX +Int 1)
       ... </k>
       <eth1-data>
         E1Data => setDepositRoot(E1Data,
            //List[DepositData, 2**DEPOSIT_CONTRACT_TREE_DEPTH]
            hash_tree_root_list(slice(Leaves, 0, INDEX +Int 1), 2 ^Int DEPOSIT_CONTRACT_TREE_DEPTH, %container, false))
       </eth1-data>

  rule <k> processEth1Deposits(.DepositList, .DepositDataList, _) => .K ... </k>

  syntax Eth1Data ::= setDepositRoot(Eth1Data, Hash) [function]
  rule setDepositRoot(#Eth1Data(DROOT, COUNT, BHASH), NewDROOT) => #Eth1Data(NewDROOT, COUNT, BHASH)

  syntax DepositDataList ::= getDataList(DepositList) [function]
  rule getDataList(Dep Deps) => Dep.data getDataList(Deps)
  rule getDataList(.DepositList) => .DepositDataList

  syntax KItem ::= "processEth1Activations" "(" Int "," Int ")"
  rule <k> processEth1Activations(COUNT, INDEX => INDEX +Int 1)
       ... </k>
       <balances> INDEX |-> BAL </balances>
       <validators> INDEX |-> #Validator(_,_,
                                 (_ => minInt(BAL -Int BAL %Int EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE)),
                                 _,
                                 (AEE => #if MAX_EFFECTIVE_BALANCE <=Int BAL -Int BAL %Int EFFECTIVE_BALANCE_INCREMENT
                                         #then GENESIS_EPOCH
                                         #else AEE
                                         #fi),
                                 (AE  => #if MAX_EFFECTIVE_BALANCE <=Int BAL -Int BAL %Int EFFECTIVE_BALANCE_INCREMENT
                                         #then GENESIS_EPOCH
                                         #else AE
                                         #fi),
                                 _,_)
       </validators>
    requires INDEX <Int COUNT

  rule <k> processEth1Activations(COUNT, INDEX) => .K ... </k>
    requires INDEX >=Int COUNT

  syntax KItem ::= "populateEth1Roots" "(" Hash "," Hash "," Int "," Int ")"
  rule <k> populateEth1Roots(AIRoot, CCRoot, Index => Index +Int 1, Count) ... </k>
       <active-index-roots> AIRoots => setRootAt(Index, AIRoots, AIRoot) </active-index-roots>
       <compact-committees-roots> CCRoots=> setRootAt(Index, CCRoots, CCRoot) </compact-committees-roots>
    requires Index <Int Count

  rule <k> populateEth1Roots(_, _, Index, Count) => .K ... </k>
    requires Index >=Int Count

/*
def is_valid_genesis_state(state: BeaconState) -> bool:
    if state.genesis_time < MIN_GENESIS_TIME:
        return False
    if len(get_active_validator_indices(state, GENESIS_EPOCH)) < MIN_GENESIS_ACTIVE_VALIDATOR_COUNT:
        return False
    return True
*/
  syntax Bool ::= "is_valid_genesis_state" "(" ")" [function]
  rule [[ is_valid_genesis_state()
       => #if Gtime <Int MIN_GENESIS_TIME
              orBool len(get_active_validator_indices(GENESIS_EPOCH)) <Int MIN_GENESIS_ACTIVE_VALIDATOR_COUNT
          #then false
          #else true
          #fi ]]
       <genesis-time> Gtime </genesis-time>


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
  syntax Kitem ::= "state_transition" "(" Bool ")"
  rule <k> state_transition(VSR) => process_slots(BSLOT) ~> process_block() ~> validate_state_root(VSR) ...</k>
       <blockSlot> BSLOT </blockSlot>

  syntax Kitem ::= "validate_state_root" "(" Bool ")"
    rule <k> validate_state_root(VSR) => .K ...</k>
         <state-root> BSR </state-root>
      requires (notBool VSR) orBool (BSR ==K hash_tree_root_state())

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
  syntax KItem ::= "process_slots" "(" Int ")"
  rule <k> process_slots(SLOT) => processSlotsLoop(SLOT) ...</k>
       <slot> SSLOT </slot>
    requires SSLOT <=Int SLOT

  syntax KItem ::= "processSlotsLoop" "(" Int ")"
  rule <k> processSlotsLoop(SLOT) =>
             process_slot()   ~>
             #if (SSLOT +Int 1) %Int SLOTS_PER_EPOCH ==K 0 #then process_epoch() #else .K #fi ~>
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
    if state.latest_block_header.state_root == Bytes32():
        state.latest_block_header.state_root = previous_state_root
    # Cache block root
    previous_block_root = signing_root(state.latest_block_header)
    state.block_roots[state.slot % SLOTS_PER_HISTORICAL_ROOT] = previous_block_root
*/
  syntax KItem ::= "process_slot" "(" ")"
  rule <k> process_slot() =>
             processSlotAux(hash_tree_root_state(), SLOT %Int SLOTS_PER_HISTORICAL_ROOT)
       ...</k>
       <slot> SLOT </slot>

  syntax KItem ::= "processSlotAux" "(" previousStateRoot: Hash "," stateRootsIndex: Int ")"
  rule <k> processSlotAux(HTROOT, SLOT) => cacheBlockRoot(SLOT) ... </k>
       <state-roots> SLOT |-> (_ => HTROOT) </state-roots>
       <latest-block-header> #BeaconBlockHeader(_,_, BLOCKSTATEROOT
                                                     => #if BLOCKSTATEROOT =/=K defaultHash()
                                                          #then HTROOT
                                                          #else BLOCKSTATEROOT
                                                        #fi , _,_) </latest-block-header>

  syntax KItem ::= "cacheBlockRoot" "(" Int ")"
  rule <k> cacheBlockRoot(SLOT) => .K ...</k>
       <latest-block-header> LatestBlockHEADER </latest-block-header>
       <block-roots> SLOT |-> (_ => signing_root(LatestBlockHEADER)) </block-roots>


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
  syntax KItem ::= "process_epoch" "(" ")"
  rule <k> process_epoch() =>
                process_justification_and_finalization()
             ~> process_crosslinks()
             ~> process_rewards_and_penalties()
             ~> process_registry_updates()
             ~> process_slashings()
             ~> process_final_updates()
       ... </k>

/*
def get_matching_source_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    assert epoch in (get_previous_epoch(state), get_current_epoch(state))
    return state.current_epoch_attestations if epoch == get_current_epoch(state) else state.previous_epoch_attestations
*/
  syntax PendingAttestationList ::= "get_matching_source_attestations" "(" Int ")" [function]
  rule [[ get_matching_source_attestations(EPOCH) =>
    #if EPOCH ==K get_current_epoch() #then CEA #else PEA #fi ]]
    <current-epoch-attestations> CEA </current-epoch-attestations>
    <previous-epoch-attestations> PEA </previous-epoch-attestations>

/*
def get_matching_target_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    return [
        a for a in get_matching_source_attestations(state, epoch)
        if a.data.target.root == get_block_root(state, epoch)
    ]
*/
  syntax PendingAttestationList ::= "get_matching_target_attestations" "(" Int ")" [function]
  rule get_matching_target_attestations(EPOCH) =>
         filterOutNonMatchingTargets(get_matching_source_attestations(EPOCH), EPOCH, .PendingAttestationList)

  syntax PendingAttestationList ::= filterOutNonMatchingTargets(PendingAttestationList, Int, PendingAttestationList) [function]
  rule filterOutNonMatchingTargets(PA PAList => PAList, EPOCH, RES => RES +append PA)
    requires PA.data.target.root ==K get_block_root(EPOCH)
  rule filterOutNonMatchingTargets(PA PAList => PAList, EPOCH, RES)
    requires PA.data.target.root =/=K get_block_root(EPOCH)
  rule filterOutNonMatchingTargets(.PendingAttestationList, EPOCH, RES) => RES

/*
def get_matching_head_attestations(state: BeaconState, epoch: Epoch) -> Sequence[PendingAttestation]:
    return [
        a for a in get_matching_source_attestations(state, epoch)
        if a.data.beacon_block_root == get_block_root_at_slot(state, get_attestation_data_slot(state, a.data))
    ]
*/
  syntax PendingAttestationList ::= "get_matching_head_attestations" "(" Int ")" [function]
  rule get_matching_head_attestations(EPOCH) =>
         filterOutNonMatchingHeads(get_matching_source_attestations(EPOCH), .PendingAttestationList)

  syntax PendingAttestationList ::= filterOutNonMatchingHeads(PendingAttestationList, PendingAttestationList) [function]
  rule filterOutNonMatchingHeads(PA PAL => PAL, PAL' => PAL' +append PA)
    requires PA.data.beaconBlockRoot ==K get_block_root_at_slot(get_attestation_data_slot(PA.data))
  rule filterOutNonMatchingHeads(PA PAL => PAL, PAL')
    requires PA.data.beaconBlockRoot =/=K get_block_root_at_slot(get_attestation_data_slot(PA.data))
  rule filterOutNonMatchingHeads(.PendingAttestationList, PAL') => PAL'

/*
def get_unslashed_attesting_indices(state: BeaconState,
                                    attestations: Sequence[PendingAttestation]) -> Set[ValidatorIndex]:
    output = set()  # type: Set[ValidatorIndex]
    for a in attestations:
        output = output.union(get_attesting_indices(state, a.data, a.aggregation_bits))
    return set(filter(lambda index: not state.validators[index].slashed, output))
*/
  syntax IntList ::= "get_unslashed_attesting_indices" "(" PendingAttestationList ")" [function]
  rule get_unslashed_attesting_indices(PAL) => filterOutSlashedIndices(getAttestingIndicesLoop(PAL, .IntList))

  // merging, instead of concatenation, of lists is performed
  syntax IntList ::= getAttestingIndicesLoop(PendingAttestationList, IntList) [function]
  rule getAttestingIndicesLoop(PA PAL => PAL, IL => (IL ++IntList get_attesting_indices(PA.data, PA.aggregationBits)))
  rule getAttestingIndicesLoop(.PendingAttestationList, IL) => IL

  syntax IntList ::= filterOutSlashedIndices(IntList) [function]
  rule filterOutSlashedIndices(I IL) => #if getValidator(I).slashed
                                          #then filterOutSlashedIndices(IL)
                                          #else I filterOutSlashedIndices(IL)
                                        #fi
  rule filterOutSlashedIndices(.IntList) => .IntList

/*
def get_attesting_balance(state: BeaconState, attestations: Sequence[PendingAttestation]) -> Gwei:
    return get_total_balance(state, get_unslashed_attesting_indices(state, attestations))
*/
  syntax Int ::= "get_attesting_balance" "(" PendingAttestationList ")" [function]
  rule get_attesting_balance(PAL) => get_total_balance(get_unslashed_attesting_indices(PAL))

/*
def get_winning_crosslink_and_attesting_indices(state: BeaconState,
                                                epoch: Epoch,
                                                shard: Shard) -> Tuple[Crosslink, Set[ValidatorIndex]]:
    attestations = [a for a in get_matching_source_attestations(state, epoch) if a.data.crosslink.shard == shard]
    crosslinks = filter(
        lambda c: hash_tree_root(state.current_crosslinks[shard]) in (c.parent_root, hash_tree_root(c)),
        [a.data.crosslink for a in attestations]
    )
    # Winning crosslink has the crosslink data root with the most balance voting for it (ties broken lexicographically)
    winning_crosslink = max(crosslinks, key=lambda c: (
        get_attesting_balance(state, [a for a in attestations if a.data.crosslink == c]), c.data_root
    ), default=Crosslink())
    winning_attestations = [a for a in attestations if a.data.crosslink == winning_crosslink]
    return winning_crosslink, get_unslashed_attesting_indices(state, winning_attestations)
*/
  syntax CrosslinkIntListPair ::= "get_winning_crosslink_and_attesting_indices" "(" Int "," Int ")" [function]
  rule get_winning_crosslink_and_attesting_indices(EPOCH, SHARD)
       => #fun(ATTESTATIONS
       => #fun(CROSSLINKS
       => #fun(WinningCrosslink
       => #fun(WinningAttestations
       => #crosslinkIntListPair( WinningCrosslink, get_unslashed_attesting_indices(WinningAttestations) )
          )(pendingAttestationsMatchingCrosslink(ATTESTATIONS, WinningCrosslink, .PendingAttestationList))
          )(maxCrosslinkOnBalanceAndRoot(CROSSLINKS, ATTESTATIONS, .CrosslinkList, -1, ""))
          )(getCrosslinksOfAttestationsMatchingShardCrosslink(ATTESTATIONS, SHARD, .CrosslinkList))
          )(getMatchingShardSourceAttestations(EPOCH, SHARD))

//attestations = [a for a in get_matching_source_attestations(state, epoch) if a.data.crosslink.shard == shard]
  syntax PendingAttestationList ::= getMatchingShardSourceAttestations(epoch: Int, shard: Int)      [function]
  rule getMatchingShardSourceAttestations(EPOCH, SHARD)
       => pendingAttestationsMatchingShard(get_matching_source_attestations(EPOCH), SHARD, .PendingAttestationList)

/*  crosslinks = filter(
        lambda c: hash_tree_root(state.current_crosslinks[shard]) in (c.parent_root, hash_tree_root(c)),
        [a.data.crosslink for a in attestations]
    )
*/
  syntax CrosslinkList ::= getCrosslinksOfAttestationsMatchingShardCrosslink(PendingAttestationList,
                                                                             shard: Int, result: CrosslinkList) [function]
  rule getCrosslinksOfAttestationsMatchingShardCrosslink(PATT PATTList, SHARD, RES)
       => #fun(CROSSLINK
       => getCrosslinksOfAttestationsMatchingShardCrosslink( PATTList, SHARD,
            #if hash_tree_root(getCurrentCrosslink(SHARD))
                in ( SetItem(CROSSLINK.parentRoot) SetItem(hash_tree_root(CROSSLINK)) )
              #then RES +append CROSSLINK
              #else RES
            #fi
          )
          )(PATT.data.crosslink)

  rule getCrosslinksOfAttestationsMatchingShardCrosslink(.PendingAttestationList, _, RES) => RES

/*  winning_crosslink = max(crosslinks, key=lambda c: (
        get_attesting_balance(state, [a for a in attestations if a.data.crosslink == c]), c.data_root
    ), default=Crosslink())
*/
  syntax Crosslink ::= maxCrosslinkOnBalanceAndRoot(CrosslinkList, PendingAttestationList,
                                                    result: CrosslinkList, maxBalance: Int, maxRoot: Hash) [function]
  rule maxCrosslinkOnBalanceAndRoot( CROSSLINK CrosslinkList, PendAttList, RES, MaxBalance, MaxRoot )
        => #fun(BALANCE
        => #fun(ROOT
        => maxCrosslinkOnBalanceAndRoot(CrosslinkList, PendAttList,
                                        #if        BALANCE >Int MaxBalance
                                           orBool (BALANCE ==Int MaxBalance andBool ROOT >String MaxRoot)
                                          #then CROSSLINK .CrosslinkList
                                          #else RES
                                        #fi,
                                        #if        BALANCE >Int MaxBalance
                                           orBool (BALANCE ==Int MaxBalance andBool ROOT >String MaxRoot)
                                          #then BALANCE
                                          #else MaxBalance
                                        #fi,
                                        #if        BALANCE >Int MaxBalance
                                           orBool (BALANCE ==Int MaxBalance andBool ROOT >String MaxRoot)
                                          #then ROOT
                                          #else MaxRoot
                                        #fi
           )
           )(CROSSLINK.dataRoot)
           )( get_attesting_balance(pendingAttestationsMatchingCrosslink(PendAttList, CROSSLINK, .PendingAttestationList)) )

  rule maxCrosslinkOnBalanceAndRoot(.CrosslinkList, _, CROSSLINK:Crosslink, _,_ ) => CROSSLINK
  rule maxCrosslinkOnBalanceAndRoot(.CrosslinkList, _, .CrosslinkList, _,_ ) => defaultCrosslink()

  // extracts the list of attestations for the given shard
  syntax PendingAttestationList ::= pendingAttestationsMatchingShard(PendingAttestationList, Int,
                                                                     PendingAttestationList) [function]
  rule pendingAttestationsMatchingShard( PA PAList => PAList,
                                         SHARD,
                                         RES => #if PA.data.crosslink.shard ==Int SHARD
                                                  #then RES +append PA
                                                  #else RES
                                                #fi)
  rule pendingAttestationsMatchingShard(.PendingAttestationList, _, RES) => RES

//winning_attestations = [a for a in attestations if a.data.crosslink == CROSSLINK]
  syntax PendingAttestationList ::= pendingAttestationsMatchingCrosslink(PendingAttestationList, Crosslink,
                                                                         PendingAttestationList) [function]
  rule pendingAttestationsMatchingCrosslink( PA PAL => PAL,
                                             CROSSLINK,
                                             RES => #if PA.data.crosslink ==K CROSSLINK
                                                      #then RES +append PA
                                                      #else RES
                                                    #fi)
  rule pendingAttestationsMatchingCrosslink(.PendingAttestationList, _, RES) => RES

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
  syntax KItem ::= "process_justification_and_finalization" "(" ")" [klabel(process_justification_and_finalization), symbol]

  // too early to proceed with processing
  rule <k> (process_justification_and_finalization() => .K) ... </k>
    requires get_current_epoch() <=Int GENESIS_EPOCH +Int 1

/*  state.previous_justified_checkpoint = state.current_justified_checkpoint
    state.justification_bits[1:] = state.justification_bits[:-1]
    state.justification_bits[0] = 0b0
*/
  rule <k> process_justification_and_finalization()
           => updateJustificationPrev(get_previous_epoch())
           ~> updateJustificationCurr(get_current_epoch())
           ~> updateFinalization(PrevJustCHECKP, CurrJustCHECKP)
       ... </k>
       <previous-justified-checkpoint> PrevJustCHECKP => CurrJustCHECKP </previous-justified-checkpoint>
       <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
       <justification-bits> Bits => false removeLast(Bits) </justification-bits>
    requires get_current_epoch() >Int GENESIS_EPOCH +Int 1

/*  matching_target_attestations = get_matching_target_attestations(state, previous_epoch)  # Previous epoch
    if get_attesting_balance(state, matching_target_attestations) * 3 >= get_total_active_balance(state) * 2:
        state.current_justified_checkpoint = Checkpoint(epoch=previous_epoch,
                                                        root=get_block_root(state, previous_epoch))
        state.justification_bits[1] = 0b1
*/
  syntax KItem ::= "updateJustificationPrev" "(" Int ")"
  rule <k> updateJustificationPrev(PrevEPOCH) => .K ... </k>
       <current-justified-checkpoint>
          CurrJustCHECKP => #Checkpoint(PrevEPOCH, get_block_root(PrevEPOCH))
       </current-justified-checkpoint>
       <justification-bits> Bits => setBitAt(Bits, 1, true) </justification-bits>
    requires get_attesting_balance(get_matching_target_attestations(PrevEPOCH)) *Int 3 >=Int get_total_active_balance() *Int 2

  rule <k> updateJustificationPrev(PrevEPOCH) => .K ... </k>
       <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
       <justification-bits> Bits </justification-bits>
    [owise]

  syntax KItem ::= "updateJustificationCurr" "(" Int ")"
  rule <k> updateJustificationCurr(CurrEPOCH) => .K ... </k>
       <current-justified-checkpoint>
          CurrJustCHECKP => #Checkpoint(CurrEPOCH, get_block_root(CurrEPOCH))
       </current-justified-checkpoint>
       <justification-bits> Bits => setBitAt(Bits, 0, true) </justification-bits>
    requires get_attesting_balance(get_matching_target_attestations(CurrEPOCH)) *Int 3 >=Int get_total_active_balance() *Int 2
  rule <k> updateJustificationCurr(CurrEPOCH) => .K ... </k>
       <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
       <justification-bits> Bits </justification-bits>
    requires notBool get_attesting_balance(get_matching_target_attestations(CurrEPOCH)) *Int 3 >=Int get_total_active_balance() *Int 2

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
         FCP => #if allOnes(slice(Bits, 1, 4)) andBool OldPrevJustCP.epoch +Int 3 ==K get_current_epoch()
                #then OldPrevJustCP
                #else FCP
                #fi
       </finalized-checkpoint>

  // if all(bits[1:3]) and old_previous_justified_checkpoint.epoch + 2 == current_epoch:
  syntax KItem ::= "updateFinalizedCheckpoint2" "(" Checkpoint "," BitList ")"
  rule <k> updateFinalizedCheckpoint2(OldPrevJustCP, Bits) => .K ... </k>
       <finalized-checkpoint>
         FCP => #if allOnes(slice(Bits, 1, 3)) andBool OldPrevJustCP.epoch +Int 2 ==K get_current_epoch()
                #then OldPrevJustCP
                #else FCP
                #fi
       </finalized-checkpoint>

  // if all(bits[0:3]) and old_current_justified_checkpoint.epoch + 2 == current_epoch:
  syntax KItem ::= "updateFinalizedCheckpoint3" "(" Checkpoint "," BitList ")"
  rule <k> updateFinalizedCheckpoint3(OldCurrJustCP, Bits) => .K ... </k>
       <finalized-checkpoint>
         FCP => #if allOnes(slice(Bits, 0, 3)) andBool OldCurrJustCP.epoch +Int 2 ==K get_current_epoch()
                #then OldCurrJustCP
                #else FCP
                #fi
       </finalized-checkpoint>

  // if all(bits[0:2]) and old_current_justified_checkpoint.epoch + 1 == current_epoch:
  syntax KItem ::= "updateFinalizedCheckpoint4" "(" Checkpoint "," BitList ")"
  rule <k> updateFinalizedCheckpoint4(OldCurrJustCP, Bits) => .K ... </k>
       <finalized-checkpoint>
         FCP => #if allOnes(slice(Bits, 0, 2)) andBool OldCurrJustCP.epoch +Int 1 ==K get_current_epoch()
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
  syntax KItem ::= "process_crosslinks" "(" ")" [klabel(process_crosslinks), symbol]
  rule <k> process_crosslinks()
           => processCrosslinksForEpoch(get_previous_epoch())
           ~> processCrosslinksForEpoch(get_current_epoch()) ... </k>
       <previous-crosslinks> PCL => CCL </previous-crosslinks>
       <current-crosslinks> CCL  </current-crosslinks>

  syntax KItem ::= "processCrosslinksForEpoch" "(" Int ")"
  rule <k> processCrosslinksForEpoch(EP) => processCrosslinksForEpochLoop(0, get_committee_count(EP), EP) ... </k>

  syntax KItem ::= "processCrosslinksForEpochLoop" "(" Int "," Int "," Int ")"
  rule <k> processCrosslinksForEpochLoop(OFFSET => OFFSET +Int 1, COUNT, EP) ... </k>
       <current-crosslinks>
         CROSSLINKS
         => #fun(SHARD
         => #fun(CrosslinkCommittee
         => #fun(WinCrossAndIndices
         => #if ( 3 *Int get_total_balance(WinCrossAndIndices.intList) >=Int 2 *Int get_total_balance(CrosslinkCommittee) )
              #then CROSSLINKS[SHARD <- WinCrossAndIndices.crosslink]
              #else CROSSLINKS
            #fi
            )(get_winning_crosslink_and_attesting_indices(EP, SHARD))
            )(get_crosslink_committee(EP, SHARD))
            )((get_start_shard(EP) +Int OFFSET) %Int SHARD_COUNT)
       </current-crosslinks>
    requires OFFSET <Int COUNT

  rule <k> processCrosslinksForEpochLoop(OFFSET, COUNT, EP) => .K ... </k>
    requires OFFSET >=Int COUNT


/*
def get_base_reward(state: BeaconState, index: ValidatorIndex) -> Gwei:
    total_balance = get_total_active_balance(state)
    effective_balance = state.validators[index].effective_balance
    return Gwei(effective_balance * BASE_REWARD_FACTOR // integer_squareroot(total_balance) // BASE_REWARDS_PER_EPOCH)
*/
  syntax Int ::= "get_base_reward" "(" Int ")" [function]
  rule get_base_reward(INDEX)
       => getValidator(INDEX).effectiveBalance *Int BASE_REWARD_FACTOR
          /Int integer_squareroot(get_total_active_balance())
          /Int BASE_REWARDS_PER_EPOCH

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
  syntax MapMapPair ::= "get_attestation_deltas" "(" ")" [function]
  rule get_attestation_deltas()
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
           getEligibleValidatorIndices(get_previous_epoch()),
           get_unslashed_attesting_indices(get_matching_head_attestations(get_previous_epoch())),
           get_total_balance(get_unslashed_attesting_indices(get_matching_head_attestations(get_previous_epoch()))),
           microIncentivesAfterTargetAtt() )

  syntax MapMapPair ::= microIncentivesAfterTargetAtt() [function]
  rule microIncentivesAfterTargetAtt() =>
         loopOverEligibleValidatorIndices(
           getEligibleValidatorIndices(get_previous_epoch()),
           get_unslashed_attesting_indices(get_matching_target_attestations(get_previous_epoch())),
           get_total_balance(get_unslashed_attesting_indices(get_matching_target_attestations(get_previous_epoch()))),
           microIncentivesAfterSourceAtt() )

  syntax MapMapPair ::= microIncentivesAfterSourceAtt() [function]
  rule microIncentivesAfterSourceAtt() =>
         loopOverEligibleValidatorIndices(
           getEligibleValidatorIndices(get_previous_epoch()),
           get_unslashed_attesting_indices(get_matching_source_attestations(get_previous_epoch())),
           get_total_balance(get_unslashed_attesting_indices(get_matching_source_attestations(get_previous_epoch()))),
           #mapMapPair( initMapOfSize(numOfValidators()), initMapOfSize(numOfValidators())) )

  syntax MapMapPair ::= loopOverEligibleValidatorIndices(IntList, IntList, Int, MapMapPair) [function]
  rule loopOverEligibleValidatorIndices(I IL => IL,
                       UnslashedIndices,
                       AttestingBalance,
                       #mapMapPair(Rewards => #if contains(I, UnslashedIndices)
                                              #then Rewards[I <- ({Rewards[I]}:>Int +Int get_base_reward(I) *Int AttestingBalance)]
                                              #else Rewards
                                              #fi,
                                  Penalties => #if notBool contains(I, UnslashedIndices)
                                               #then Penalties[I <- ({Penalties[I]}:>Int +Int get_base_reward(I))]
                                               #else Penalties
                                               #fi) )

  rule loopOverEligibleValidatorIndices(.IntList, _, _, RewardsPenalties) => RewardsPenalties

  // Second step in computing rewards
  syntax Map ::= delayMicroRewards(Map) [function]
  rule delayMicroRewards(Rewards) =>
         loopOverUnslashedAttestingIndices(
           get_unslashed_attesting_indices(get_matching_source_attestations(get_previous_epoch())),
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
                                                     filterAttForIndex(get_matching_source_attestations(get_previous_epoch()), I)
                                                   ).inclusionDelay )
                                        /Int SLOTS_PER_EPOCH)) ]
       )
  rule loopOverUnslashedAttestingIndices(.IntList, Rewards) => Rewards

  syntax Map ::= updateMinDelayAttReward(Map, Int) [function]
  rule updateMinDelayAttReward(Rewards, I) =>
          updateAttProposerReward(
            Rewards,
            findMinDelayAttestation(filterAttForIndex(get_matching_source_attestations(get_previous_epoch()), I)),
            computeProposerReward(I))

  // rewards[attestation.proposer_index] += proposer_reward
  syntax Map ::= updateAttProposerReward(Map /*Rewards*/, PendingAttestation /*attestation*/, Int /*proposer_reward*/ ) [function]
  rule updateAttProposerReward(Rewards, Attestation, PropReward)
       => Rewards[Attestation.proposerIndex <- {Rewards[Attestation.proposerIndex]}:>Int +Int PropReward]

  // max_attester_reward = get_base_reward(state, index) - proposer_reward
  syntax Int ::= computeMaxAttReward(Int /*Proposer index*/ , Int /*proposer reward*/) [function]
  rule computeMaxAttReward(INDEX, REWARD) => get_base_reward(INDEX) -Int REWARD

  // proposer_reward = Gwei(get_base_reward(state, index) // PROPOSER_REWARD_QUOTIENT)
  syntax Int ::= computeProposerReward(Int /*proposer index*/) [function]
  rule computeProposerReward(INDEX) => get_base_reward(INDEX) /Int PROPOSER_REWARD_QUOTIENT

  /*
  attestation = min([
              a for a in matching_source_attestations
              if index in get_attesting_indices(state, a.data, a.aggregation_bits)
          ], key=lambda a: a.inclusion_delay)
  */
  syntax PendingAttestationList ::= filterAttForIndex(PendingAttestationList, Int) [function]
  rule filterAttForIndex(PA PAL, INDEX)
       => #if contains(INDEX, get_attesting_indices(PA.data, PA.aggregationBits))
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
            getEligibleValidatorIndices(get_previous_epoch()),
            get_unslashed_attesting_indices(get_matching_target_attestations(get_previous_epoch())),
            Penalties)

  syntax Map ::= loopOverEligibleValsForPen(IntList, IntList, Map) [function]
  rule loopOverEligibleValsForPen(
         I IL => IL,
         UnslashedIndices,
         Penalties => #if notBool contains(I, UnslashedIndices)
                        #then (updateBasePenalties(Penalties, I))[I <- {(updateBasePenalties(Penalties, I))[I]}:>Int
                                +Int (getValidator(I).effectiveBalance *Int computeFinalityDelay() /Int INACTIVITY_PENALTY_QUOTIENT)]
                        #else updateBasePenalties(Penalties, I)
                      #fi )

  rule loopOverEligibleValsForPen(.IntList, _, Penalties) => Penalties

  // finality_delay = previous_epoch - state.finalized_checkpoint.epoch
  syntax Int ::= computeFinalityDelay() [function]
  rule [[ computeFinalityDelay() => get_previous_epoch() -Int FCP.epoch ]]
       <finalized-checkpoint> FCP </finalized-checkpoint>

  // penalties[index] += Gwei(BASE_REWARDS_PER_EPOCH * get_base_reward(state, index))
  syntax Map ::= updateBasePenalties(Map, Int) [function]
  rule updateBasePenalties(Penalties, INDEX)
       => Penalties[INDEX <- {Penalties[INDEX]}:>Int +Int (BASE_REWARDS_PER_EPOCH *Int get_base_reward(INDEX))]

  syntax Int ::= numOfValidators() [function]
  rule [[ numOfValidators() => size(ValMap) ]]
       <validators> ValMap </validators>

  syntax IntList ::= getEligibleValidatorIndices(Int) [function]
  rule [[ getEligibleValidatorIndices(PrevEP) => getEligibleValidatorIndicesLoop(PrevEP, 0, size(VMap), .IntList) ]]
    <validators> VMap </validators>

  syntax IntList ::= getEligibleValidatorIndicesLoop(Int, Int, Int, IntList) [function]
  rule getEligibleValidatorIndicesLoop(PrevEP, I, N, IL)
       => #fun(VAL
       => #if is_active_validator(VAL, PrevEP) orBool (VAL.slashed andBool PrevEP +Int 1 <Int VAL.withdrawableEpoch)
            #then getEligibleValidatorIndicesLoop(PrevEP, I +Int 1, N, IL I)
            #else getEligibleValidatorIndicesLoop(PrevEP, I +Int 1, N, IL)
          #fi
              )(getValidator(I))
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
  syntax MapMapPair ::= "get_crosslink_deltas" "(" ")" [function]
  rule get_crosslink_deltas() => getCrosslinkDeltasOffsetLoop(
                                 0,                                             // Offset counter
                                 get_committee_count(get_previous_epoch()),         // Offset upper bound
                                 get_previous_epoch(),                            // Previous epoch
                                 #mapMapPair(
                                   initMapOfSize(numOfValidators()),               // Rewards
                                   initMapOfSize(numOfValidators()))               // Penalties
                                 )

  // outer offset loop
  syntax MapMapPair ::= getCrosslinkDeltasOffsetLoop(Int, Int, Int, MapMapPair) [function]
  rule getCrosslinkDeltasOffsetLoop(
         Offset => Offset +Int 1, N, EP,
         RewPen => getCrosslinkDeltasIndexLoop(
                      get_crosslink_committee(EP, getOffsetShard(Offset)),                                            // Crosslink committee
                      get_winning_crosslink_and_attesting_indices(EP, getOffsetShard(Offset)).intList,                   // Attesting indices
                      get_total_balance(get_winning_crosslink_and_attesting_indices(EP, getOffsetShard(Offset)).intList),  // Attesting balance
                      get_total_balance(get_crosslink_committee(EP, getOffsetShard(Offset))),                           // Committee balance
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
                      Rewards[INDEX <- ({Rewards[INDEX]}:>Int +Int get_base_reward(INDEX) *Int AttestingBalance /Int CommitteeBalance)],
                      Penalties)
              #else #mapMapPair(
                      Rewards,
                      Penalties[INDEX <- ({Penalties[INDEX]}:>Int +Int get_base_reward(INDEX))])
              #fi
       )
  rule getCrosslinkDeltasIndexLoop(.IntList, _, _, _, RewPen) => RewPen

  syntax Int ::= getOffsetShard(Int) [function]
  rule getOffsetShard(Offset) => (get_start_shard(get_previous_epoch()) +Int Offset) %Int SHARD_COUNT

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
  syntax KItem ::= "process_rewards_and_penalties" "(" ")" [klabel(process_rewards_and_penalties), symbol]
  rule <k> process_rewards_and_penalties()
       => #if get_current_epoch() ==K GENESIS_EPOCH
          #then .K
          #else processRewardsAndPenaltiesLoop(
                  0,
                  numOfValidators(),
                  get_attestation_deltas(),
                  get_crosslink_deltas())
          #fi
       ... </k>

  syntax KItem ::= "processRewardsAndPenaltiesLoop" "(" Int "," Int "," MapMapPair "," MapMapPair ")"
  rule <k> (. => increase_balance(INDEX, {Rewards1[INDEX]}:>Int +Int {Rewards2[INDEX]}:>Int)
              ~> decrease_balance(INDEX, {Penalties1[INDEX]}:>Int +Int {Penalties2[INDEX]}:>Int)
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
  syntax KItem ::= "process_registry_updates" "(" ")" [klabel(process_registry_updates), symbol]
  rule <k> process_registry_updates()
           => processRegistryUpdatesLoop1(VALIDATORS)
           ~> processActivationQueue()
         ...
       </k>
       <validators> VALIDATORS </validators>

  //we will process validators in any order, not strictly increasing index like in python
  syntax KItem ::= "processRegistryUpdatesLoop1" "(" Map ")" //validators
  rule <k> (. => #if is_active_validator(VAL, get_current_epoch())
                      andBool VAL.effectiveBalance <=Int EJECTION_BALANCE
                    #then initiate_validator_exit(INDEX)
                    #else .K
                 #fi
           )
           ~> processRegistryUpdatesLoop1(_:Map (INDEX |-> VAL => .Map) )
       ...</k>
       <validators>... INDEX |-> (#Validator(_,_,_,_,
          ActEligibilityEpoch
          => #if ActEligibilityEpoch ==Int FAR_FUTURE_EPOCH
                 andBool VAL.effectiveBalance >=Int MAX_EFFECTIVE_BALANCE
                #then get_current_epoch()
                #else ActEligibilityEpoch
             #fi,
          _,_,_) #as VAL) ...</validators>

  rule processRegistryUpdatesLoop1(.Map) => .K

  syntax KItem ::= processActivationQueue()
                 | processActivationQueue( activationQueue: IntList , churnLimit: Int )

  //must be done here instead of main rule, basause it needs state updated by Loop1
  rule <k> processActivationQueue() => processActivationQueue(
          sortActivationQueue(getActivationQueueUnsorted(0, VALIDATORS, .IntList)),
          get_validator_churn_limit() )
          ...
       </k>
       <validators> VALIDATORS </validators>

  rule <k> processActivationQueue(INDEX:Int IL => IL, I => I -Int 1) ... </k>
       <validators>... INDEX |-> #Validator(_,_,_,_,_,
          ActEpoch => compute_activation_exit_epoch(get_current_epoch()), _,_)
          ...</validators>
    requires I >Int 0
             andBool ActEpoch ==K FAR_FUTURE_EPOCH

  rule processActivationQueue(INDEX:Int IL => IL, I => I -Int 1)
    requires I >Int 0
             andBool getValidator(INDEX).activationEpoch =/=K FAR_FUTURE_EPOCH

  rule processActivationQueue(.IntList, _) => .K
  rule processActivationQueue(       _, 0) => .K

  /*
  index for index, validator in enumerate(state.validator_registry) if
        validator.activation_eligibility_epoch != FAR_FUTURE_EPOCH and
        validator.activation_epoch >= get_delayed_activation_exit_epoch(state.finalized_epoch) */
  syntax IntList ::= getActivationQueueUnsorted(i: Int, validators: Map, result: IntList ) [function]
  rule [[ getActivationQueueUnsorted(INDEX => INDEX +Int 1, _:Map (INDEX |-> VAL => .Map),  IL => IL +append INDEX) ]]
       <finalized-checkpoint> #Checkpoint(FinalizedEpoch, RootHash) </finalized-checkpoint>
    requires VAL.activationEligibilityEpoch =/=K FAR_FUTURE_EPOCH
         andBool VAL.activationEpoch >=Int compute_activation_exit_epoch(FinalizedEpoch)

  rule [[ getActivationQueueUnsorted(INDEX => INDEX +Int 1, _:Map (INDEX |-> VAL => .Map),  IL /*unchanged*/ ) ]]
       <finalized-checkpoint> #Checkpoint(FinalizedEpoch, RootHash) </finalized-checkpoint>
    requires notBool ( VAL.activationEligibilityEpoch =/=K FAR_FUTURE_EPOCH
                   andBool VAL.activationEpoch >=Int compute_activation_exit_epoch(FinalizedEpoch) )

  rule getActivationQueueUnsorted(_, .Map, IL ) => IL

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
  rule indexForMinEligEpoch( MIN => #if getValidator(MIN).activationEligibilityEpoch <=Int getValidator(I).activationEligibilityEpoch
                                      #then MIN #else I #fi,
                             (I:Int IL) => IL )
  rule indexForMinEligEpoch(MIN, .IntList) => MIN

/*
def process_slashings(state: BeaconState) -> None:
    epoch = get_current_epoch(state)
    total_balance = get_total_active_balance(state)
    for index, validator in enumerate(state.validators):
        if validator.slashed and epoch + EPOCHS_PER_SLASHINGS_VECTOR // 2 == validator.withdrawable_epoch:
            increment = EFFECTIVE_BALANCE_INCREMENT  # Factored out from penalty numerator to avoid uint64 overflow
            penalty_numerator = validator.effective_balance // increment * min(sum(state.slashings) * 3, total_balance)
            penalty = penalty_numerator // total_balance * increment
            decrease_balance(state, ValidatorIndex(index), penalty)
*/
  syntax KItem ::= "process_slashings" "(" ")" [klabel(process_slashings), symbol]
  rule <k> process_slashings() =>
           processSlashingsLoop(
             0,
             size(VALIDATORS),
             get_current_epoch(),
             get_total_active_balance()
           )
       ... </k>
       <validators> VALIDATORS </validators>

  syntax KItem ::= "processSlashingsLoop" "(" i: Int "," nrValidators: Int "," Int "," Int ")"
  rule (. => decrease_balance(I, (getValidator(I).effectiveBalance /Int EFFECTIVE_BALANCE_INCREMENT *Int minInt(sumSlashings() *Int 3,
                                  TotalBalance)) /Int TotalBalance *Int EFFECTIVE_BALANCE_INCREMENT))
       ~> processSlashingsLoop(I => I +Int 1, N, EP, TotalBalance)
    requires I <Int N
     andBool getValidator(I).slashed andBool EP +Int EPOCHS_PER_SLASHINGS_VECTOR /Int 2 ==K getValidator(I).withdrawableEpoch

  rule processSlashingsLoop(I => I +Int 1, N, EP, TotalBalance)
    requires I <Int N
     andBool notBool (getValidator(I).slashed andBool EP +Int EPOCHS_PER_SLASHINGS_VECTOR /Int 2 ==K getValidator(I).withdrawableEpoch)

  rule processSlashingsLoop(N, N, _, _) => .K

  syntax Int ::= sumSlashings()                                       [function]
  rule [[ sumSlashings() => sumMapIntValues(SLASHINGS) ]]
    <slashings> SLASHINGS </slashings>


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
    # Update start shard
    state.start_shard = Shard((state.start_shard + get_shard_delta(state, current_epoch)) % SHARD_COUNT)
    # Rotate current/previous epoch attestations
    state.previous_epoch_attestations = state.current_epoch_attestations
    state.current_epoch_attestations = []
*/
  syntax KItem ::= "process_final_updates" "(" ")" [klabel(process_final_updates), symbol]
  rule <k> process_final_updates()
           => updateEffectiveBalances(0, size(VALIDATORS), EFFECTIVE_BALANCE_INCREMENT /Int 2)  // param: HALF_INCREMENT
           ~> setActiveIndexRoots(get_current_epoch() +Int 1 +Int ACTIVATION_EXIT_DELAY)        // param: index_epoch
           ~> setCommitteesRoot((get_current_epoch() +Int 1) %Int EPOCHS_PER_HISTORICAL_VECTOR) // param: committee_root_position
           ~> resetSlashings((get_current_epoch() +Int 1) %Int EPOCHS_PER_SLASHINGS_VECTOR)     // param: (slashings index)
           ~> setRandaoMix((get_current_epoch() +Int 1) %Int EPOCHS_PER_SLASHINGS_VECTOR)       // param: (rnd mixes index)
           ~> setHistoricalRootAccumulator()
           ~> updateStartShard(get_current_epoch())                                             // param: current_epoch
           ~> rotateEpochAttestations()
       ... </k>
       <slot> SLOT </slot>
       <eth1-data-votes> E1DL => #if (SLOT +Int 1) %Int SLOTS_PER_ETH1_VOTING_PERIOD ==K 0
                                 #then .Eth1DataList
                                 #else E1DL
                                 #fi
       </eth1-data-votes>
       <validators> VALIDATORS </validators>

  syntax KItem ::= updateEffectiveBalances ( i: Int, nrValidators: Int, increment: Int )
  rule <k> updateEffectiveBalances(INDEX => INDEX +Int 1, N, HALF_INCREMENT) ... </k>
       <validators> ... INDEX |-> #Validator(_,_,
                                    EffBal => minInt(BAL -Int BAL %Int EFFECTIVE_BALANCE_INCREMENT, MAX_EFFECTIVE_BALANCE),
                                    _,_,_,_,_)
        ... </validators>
       <balances> ... INDEX |-> BAL ... </balances>
    requires INDEX <Int N
     andBool (BAL <Int EffBal orBool EffBal +Int 3 *Int HALF_INCREMENT <Int BAL)

  rule <k> updateEffectiveBalances(INDEX => INDEX +Int 1, N, HALF_INCREMENT) ... </k>
       <validators> ... INDEX |-> #Validator(_,_, EffBal, _,_,_,_,_) ... </validators>
       <balances> ... INDEX |-> BAL ... </balances>
    requires INDEX <Int N
     andBool notBool(BAL <Int EffBal orBool EffBal +Int 3 *Int HALF_INCREMENT <Int BAL)

  rule updateEffectiveBalances(N, N, _) => .K

  syntax KItem ::= "updateStartShard" "(" Int ")"
  rule <k> updateStartShard(EP) => .K ... </k>
       <start-shard> SHARD => (SHARD +Int get_shard_delta(EP)) %Int SHARD_COUNT </start-shard>

  syntax KItem ::= "setActiveIndexRoots" "(" Int ")"
  rule <k> setActiveIndexRoots(IndexEpoch) => .K ... </k>
       <active-index-roots> AIR
         => setRootAtIndex(AIR,
                           IndexEpoch %Int EPOCHS_PER_HISTORICAL_VECTOR,
                           //List[ValidatorIndex, VALIDATOR_REGISTRY_LIMIT]
                           hash_tree_root_list(get_active_validator_indices(IndexEpoch), VALIDATOR_REGISTRY_LIMIT, %uint64, false))
       </active-index-roots>

  syntax BytesList ::= setRootAtIndex(BytesList, Int, Bytes) [function]
  rule setRootAtIndex(I BL, INDEX, I') => I setRootAtIndex(BL, INDEX -Int 1, I')
    requires INDEX >Int 0
  rule setRootAtIndex(I BL, 0, I') => I' BL

  syntax KItem ::= "setCommitteesRoot" "(" Int ")"
  rule <k> setCommitteesRoot(CommRootPos) => .K ... </k>
       <compact-committees-roots>
         CRS => setRootAt(CommRootPos, CRS, get_compact_committees_root(get_current_epoch() +Int 1))
       </compact-committees-roots>

  syntax BytesList ::= setRootAt(Int, BytesList, Hash) [function]
  rule setRootAt(Pos, CR CRS, CR') => CR setRootAt(Pos -Int 1, CRS, CR') requires Pos >Int 0
  rule setRootAt(0, CR CRS, CR') => CR' CRS

  syntax KItem ::= "resetSlashings" "(" Int ")"
  rule <k> resetSlashings(SlashIndex) => .K ... </k>
    <slashings> ... SlashIndex |-> (I => 0) ... </slashings>

  syntax KItem ::= "setRandaoMix" "(" Int ")"
  rule <k> setRandaoMix(RndMixIndex) => .K ... </k>
    <randao-mixes> RMS => setRandaoMixAt(
                                     RMS,
                                     RndMixIndex,
                                     get_randao_mix(get_current_epoch())
                                   )
    </randao-mixes>

/*    if next_epoch % (SLOTS_PER_HISTORICAL_ROOT // SLOTS_PER_EPOCH) == 0:
        historical_batch = HistoricalBatch(block_roots=state.block_roots, state_roots=state.state_roots)
        state.historical_roots.append(hash_tree_root(historical_batch))
*/
  syntax KItem ::= setHistoricalRootAccumulator()
  rule <k> setHistoricalRootAccumulator() => .K ... </k>
    <historical-roots>
      HL:BytesList
         => #if (get_current_epoch() +Int 1) %Int (SLOTS_PER_HISTORICAL_ROOT /Int SLOTS_PER_EPOCH) ==Int 0
              #then HL +append hash_tree_root(#HistoricalBatch({mapToList(BlockRoots, 0, .BytesList)}:>BytesList,
                                                                  {mapToList(StateRoots, 0, .BytesList)}:>BytesList ))
              #else HL
            #fi
    </historical-roots>
    <block-roots> BlockRoots </block-roots>
    <state-roots> StateRoots </state-roots>

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
  syntax KItem ::= "process_block" "(" ")"
  rule <k> process_block() =>
                process_block_header()
             ~> process_randao()
             ~> process_eth1_data()
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
        # state_root: zeroed, overwritten in the next `process_slot` call
        body_root=hash_tree_root(block.body),
        # signature is always zeroed
    )
    # Verify proposer is not slashed
    proposer = state.validators[get_beacon_proposer_index(state)]
    assert not proposer.slashed
    # Verify proposer signature
    assert bls_verify(proposer.pubkey, signing_root(block), block.signature, get_domain(state, DOMAIN_BEACON_PROPOSER))
*/
  syntax KItem ::= "process_block_header" "(" ")"           [klabel(process_block_header), symbol]
  rule <k> process_block_header() => .K ... </k>
       <latest-block-header>
         OldBlockHEADER  => #BeaconBlockHeader(
                               BlockSLOT,                   // block.slot
                               ParentROOT,                  // block.parent_root
                               defaultHash(),               // zeroed
                               hash_tree_root_blockBody(),  // hash_tree_root(block.body)
                               defaultBytes96()  )          // zeroed
       </latest-block-header>
       <slot> SLOT </slot>
       <validators> ValMap </validators>
       <blockSlot> BlockSLOT </blockSlot>
       <parent-root> ParentROOT </parent-root>
    requires BlockSLOT ==K SLOT
     andBool ParentROOT ==K signing_root(OldBlockHEADER)
     andBool notBool ({ValMap[get_beacon_proposer_index()]}:>Validator).slashed

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
  syntax KItem ::= "process_randao" "(" ")"
  rule <k> process_randao() => .K ... </k>
       <randao-mixes>
         RMS => setRandaoMixAt(
                  RMS,
                  get_current_epoch() %Int EPOCHS_PER_HISTORICAL_VECTOR,
                  {xor(get_randao_mix(get_current_epoch()), hash(RandaoReveal))}:>Hash
                )
       </randao-mixes>
       <randao-reveal> RandaoReveal </randao-reveal>

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
  syntax KItem ::= "process_eth1_data" "(" ")"
  rule <k> process_eth1_data() => .K ... </k>
       <eth1-data-votes> VOTES => BlockEth1 </eth1-data-votes>
       <block-eth1-data> BlockEth1 </block-eth1-data>
     requires countEth1(VOTES BlockEth1, BlockEth1) *Int 2 >Int SLOTS_PER_ETH1_VOTING_PERIOD

  rule <k> process_eth1_data() => .K ... </k>
       <eth1-data-votes> VOTES => VOTES +append BlockEth1 </eth1-data-votes>
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

  rule <k> (. => process_proposer_slashing(ProposerSlashing))
           ~> process_operations_aux( INDEX => INDEX +Int 1, _,_,_,_,_ ) ...</k>
    <proposer-slashings>... INDEX |-> ProposerSlashing ...</proposer-slashings>

  rule <k> process_operations_aux( INDEX => -1, _,_,_,_,_ ) ...</k>
    <proposer-slashings> PSMap </proposer-slashings>
    requires notBool INDEX in keys(PSMap)

  rule (. => process_attester_slashing(AttSlashing))
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
  syntax KItem ::= "process_proposer_slashing" "(" ProposerSlashing ")" [klabel(process_proposer_slashing), symbol]
  rule process_proposer_slashing(#ProposerSlashing(ProposerIndex, HEAD1, HEAD2)) => slash_validator(ProposerIndex, .ValidatorIndex)
    requires compute_epoch_of_slot(HEAD1._slot) ==Int compute_epoch_of_slot(HEAD2._slot)
     andBool HEAD1 =/=K HEAD2
     andBool is_slashable_validator(getValidator(ProposerIndex), get_current_epoch())

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
  syntax KItem ::= "process_attester_slashing" "(" AttesterSlashing ")" [klabel(process_attester_slashing), symbol]
  rule process_attester_slashing(#AttesterSlashing( IAtt1, IAtt2 ))
    => processAttesterSlashingLoop(
        sortIntList(intersection(IAtt1.custodyBit0Indices +IntList IAtt1.custodyBit1Indices,
                                 IAtt2.custodyBit0Indices +IntList IAtt2.custodyBit1Indices)), false)
    requires is_slashable_attestation_data(IAtt1.data, IAtt2.data)
     andBool is_valid_indexed_attestation(IAtt1)
     andBool is_valid_indexed_attestation(IAtt2)

  syntax KItem ::= "processAttesterSlashingLoop" "(" IntList /*all attesting_indices*/
                                                 "," Bool /*slashed_any*/ ")"
  rule (. => slash_validator(INDEX, .ValidatorIndex))
       ~> processAttesterSlashingLoop(INDEX ILIST => ILIST, _ => true)
    requires is_slashable_validator(getValidator(INDEX), get_current_epoch())

  rule processAttesterSlashingLoop(INDEX ILIST => ILIST, _)
    requires notBool is_slashable_validator(getValidator(INDEX), get_current_epoch())

  rule processAttesterSlashingLoop(.IntList, true) => .K
  //If 2nd arg is false, evaluation will get stuck. This corresponds to "assert slashed_any"

/*
def process_attestation(state: BeaconState, attestation: Attestation) -> None:
    data = attestation.data
    assert data.crosslink.shard < SHARD_COUNT
    assert data.target.epoch in (get_previous_epoch(state), get_current_epoch(state))

    attestation_slot = get_attestation_data_slot(state, data)
    assert attestation_slot + MIN_ATTESTATION_INCLUSION_DELAY <= state.slot <= attestation_slot + SLOTS_PER_EPOCH

    committee = get_crosslink_committee(state, data.target.epoch, data.crosslink.shard)
    assert len(attestation.aggregation_bits) == len(attestation.custody_bits) == len(committee)

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
    assert data.crosslink.data_root == Bytes32()  # [to be removed in phase 1]

    # Check signature
    assert is_valid_indexed_attestation(state, get_indexed_attestation(state, attestation))
*/
  syntax KItem ::= "process_attestation" "(" Attestation ")" [klabel(process_attestation), symbol]
  rule <k> process_attestation( ATT )
           => process_attestation_if(ATT, #PendingAttestation(ATT.aggregation_bits,
                                                              ATT._data,
                                                              SLOT -Int get_attestation_data_slot(ATT._data),
                                                              get_beacon_proposer_index()))
       ...</k>
       <slot> SLOT </slot>
    requires ATT._data.crosslink.shard <Int SHARD_COUNT
     andBool (ATT._data.target.epoch) in (SetItem(get_previous_epoch()) SetItem(get_current_epoch()))
     andBool get_attestation_data_slot(ATT._data) +Int MIN_ATTESTATION_INCLUSION_DELAY <=Int SLOT
     andBool len(ATT.aggregation_bits) ==K len(ATT.custody_bits)
     andBool len(ATT.custody_bits) ==K len(get_crosslink_committee(ATT._data.target.epoch, ATT._data.crosslink.shard))
     andBool SLOT <=Int get_attestation_data_slot(ATT._data) +Int SLOTS_PER_EPOCH

  //logic starting from if statement inside `process_attestation`
  syntax KItem ::= "process_attestation_if" "(" Attestation "," PendingAttestation ")"

  //if case true
  rule <k> process_attestation_if(ATT, PendingATT)
          => process_attestation_after_if(ATT, CurrentCrosslink) ...</k>
    <current-justified-checkpoint> CurrJustCHECKP </current-justified-checkpoint>
    <current-crosslinks> ATT._data.crosslink.shard |-> CurrentCrosslink ...</current-crosslinks>
    <current-epoch-attestations> CurrEpochATTList => CurrEpochATTList +append PendingATT </current-epoch-attestations>
    requires ATT._data.target.epoch ==Int get_current_epoch() //if condition
     andBool ATT._data.source ==K CurrJustCHECKP

  //if case false
  rule <k> process_attestation_if(ATT, PendingATT)
          => process_attestation_after_if(ATT, PrevCrosslink) ...</k>
    <previous-justified-checkpoint> PrevJustCHECKP </previous-justified-checkpoint>
    <previous-crosslinks> ATT._data.crosslink.shard |-> PrevCrosslink ...</previous-crosslinks>
    <previous-epoch-attestations> PrevEpochATTList => PrevEpochATTList +append PendingATT </previous-epoch-attestations>
    requires ATT._data.target.epoch =/=Int get_current_epoch() //if condition
     andBool ATT._data.source ==K PrevJustCHECKP

  //after if inside `process_attestation`
  syntax KItem ::= "process_attestation_after_if" "(" Attestation "," Crosslink ")"
  rule process_attestation_after_if(ATT, ParentCrosslink ) => .K
    requires ATT._data.crosslink.parentRoot ==K hash_tree_root(ParentCrosslink)
     andBool ATT._data.crosslink.startEpoch ==Int ParentCrosslink.endEpoch
     andBool ATT._data.crosslink.endEpoch ==Int minInt(ATT._data.target.epoch, ParentCrosslink.endEpoch +Int MAX_EPOCHS_PER_CROSSLINK)
     andBool ATT._data.crosslink.dataRoot ==K defaultHash()
     andBool is_valid_indexed_attestation(get_indexed_attestation(ATT))


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
  syntax KItem ::= "process_deposit" "(" Deposit ")" [klabel(process_deposit), symbol]

  //case pubkey in validator_pubkeys
  rule <k> process_deposit(DEP) => increase_balance(getValidatorIndexByPubkey(DEP.data.pubkey), DEP.data.amount) ...</k>
    <eth1-deposit-index> EDI => EDI +Int 1 </eth1-deposit-index>
    <eth1-data> E1DATA </eth1-data>
    requires getValidatorIndexByPubkey(DEP.data.pubkey) =/=K .ValidatorIndex
     andBool is_valid_merkle_branch(
                 hash_tree_root(DEP.data),
                 DEP.proof,
                 DEPOSIT_CONTRACT_TREE_DEPTH +Int 1,
                 EDI,
                 E1DATA.deposit_root)

  //case pubkey not in validator_pubkeys
  rule <k> process_deposit(DEP) => .K ...</k>
    <eth1-deposit-index> EDI => EDI +Int 1 </eth1-deposit-index>
    <eth1-data> E1DATA </eth1-data>
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
     andBool is_valid_merkle_branch(
                 hash_tree_root(DEP.data),
                 DEP.proof,
                 DEPOSIT_CONTRACT_TREE_DEPTH +Int 1,
                 EDI,
                 E1DATA.deposit_root)

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
  syntax KItem ::= "process_voluntary_exit" "(" VoluntaryExit ")" [klabel(process_voluntary_exit), symbol]

  rule process_voluntary_exit(#VoluntaryExit(ExitEPOCH, ValINDEX, _)) => initiate_validator_exit(ValINDEX)
    requires is_active_validator(getValidator(ValINDEX), get_current_epoch())
     andBool getValidator(ValINDEX).exitEpoch ==Int FAR_FUTURE_EPOCH
     andBool get_current_epoch() >=Int ExitEPOCH
     andBool get_current_epoch() >=Int getValidator(ValINDEX).activationEpoch +Int PERSISTENT_COMMITTEE_PERIOD

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
  syntax KItem ::= "process_transfer" "(" Transfer ")" [klabel(process_transfer), symbol]

  rule <k> process_transfer(#Transfer( SENDER, RECIPIENT, AMOUNT, FEE, TrSLOT, PUBKEY, SIGNATURE ))
           => decrease_balance(SENDER, AMOUNT +Int FEE)
           ~> increase_balance(RECIPIENT, AMOUNT)
           ~> increase_balance(get_beacon_proposer_index(), FEE)
           ~> process_transfer_post_assert(SENDER, RECIPIENT) //last 2 asserts
       ...</k>
       <slot> SLOT </slot>
       <validators> SENDER |-> SenderVAL ...</validators>
    requires getBalance(SENDER) >=Int maxInt(AMOUNT +Int FEE, maxInt(AMOUNT, FEE))
     andBool SLOT ==Int TrSLOT
     andBool (
               SenderVAL.activationEligibilityEpoch ==Int FAR_FUTURE_EPOCH
        orBool get_current_epoch() >=Int SenderVAL.withdrawableEpoch
        orBool getBalance(SENDER) >=Int AMOUNT +Int FEE +Int MAX_EFFECTIVE_BALANCE
      )
     andBool SenderVAL.withdrawalCredentials ==K
        BLS_WITHDRAWAL_PREFIX +Bytes substrString({hash(PUBKEY)}:>String, 1, lengthString({hash(PUBKEY)}:>String))

  syntax KItem ::= "process_transfer_post_assert" "(" ValidatorIndex "," ValidatorIndex ")"
  rule process_transfer_post_assert(SENDER, RECIPIENT) => .K
    requires notBool (0 <Int getBalance(SENDER)    andBool    getBalance(SENDER) <Int MIN_DEPOSIT_AMOUNT)
     andBool notBool (0 <Int getBalance(RECIPIENT) andBool getBalance(RECIPIENT) <Int MIN_DEPOSIT_AMOUNT)

  syntax Int ::= getBalance( ValidatorIndex )                         [function]
  rule [[ getBalance(INDEX) => BAL ]]
    <balances> INDEX |-> BAL ...</balances>

  syntax Validator ::= getValidator( ValidatorIndex )                 [function]
  rule [[ getValidator(INDEX) => VAL ]]
    <validators> INDEX |-> VAL ...</validators>

  syntax Crosslink ::= getCurrentCrosslink( Int )                     [function]
  rule [[ getCurrentCrosslink(INDEX) => CROSSLINK ]]
    <current-crosslinks> INDEX |-> CROSSLINK ...</current-crosslinks>

endmodule
