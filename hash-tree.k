requires "types.k"

module HASH-TREE
  imports DOMAINS
  imports TYPES

  // Macros
  //====================================================

  syntax Int ::= "BYTES_PER_CHUNK"
  rule BYTES_PER_CHUNK => 32                                  [macro]
  syntax Int ::= "BYTES_PER_LENGTH_OFFSET"
  rule BYTES_PER_LENGTH_OFFSET => 4                           [macro]
  syntax Int ::= "BITS_PER_BYTE"
  rule BITS_PER_BYTE => 8                                     [macro]


  // Framework functions -- Crypto
  //====================================================

/* Takes a String and returns a 64-character hex-encoded string of the 32-byte SHA2-256 hash of the string.
Input `String` is interpreted as byte array, e.g. it is NOT hex-encoded.
*/
  syntax String ::= Sha256 ( String )                                 [function, hook(KRYPTO.sha256)]

/* def hash(data: bytes) -> Hash is SHA256.
*/
  syntax Hash ::= hash( Bytes )                                       [function]
  rule hash(BYTES) => {toBinary(Sha256(BYTES))}:>Hash

  syntax Bytes ::= toBinary( Bytes )                                  [function]
  rule toBinary(S) => chrChar(String2Base(substrString(S, 0, 2), 16)) +Bytes toBinary(substrString(S, 2, lengthString(S)))
    requires lengthString(S) >=Int 2
  rule toBinary("") => ""

  // Aux functions
  //====================================================

  syntax Hash ::= hashConcat(Bytes, Bytes)                            [function]
  rule hashConcat(H1, H2) => hash(H1 +Bytes H2)

  // SSZ library functions
  //====================================================

/* def serialize_basic(value: SSZValue):
    if isinstance(value, uint):
        return value.to_bytes(value.type().byte_len, 'little')
    elif isinstance(value, boolean):
        if value:
            return b'\x01'
        else:
            return b'\x00'
    else:
        raise Exception(f"Type not supported: {type(value)}")*/
  syntax Bytes ::= "serialize_basic" "(" BasicValue "," ElementType ")" [function]
  rule serialize_basic(A:Int, ElemType) => to_bytes(A, item_length(ElemType))
  rule serialize_basic(true, %bool)  => "" +String chrChar(1)
  rule serialize_basic(false, %bool) => "" +String chrChar(0)

/* Given ordered objects of the same basic type, serialize them, pack them into BYTES_PER_CHUNK (32) -byte chunks,
    right-pad the last chunk with zero bytes, and return the chunks.

def pack(values: Series):
    if isinstance(values, bytes):  # Bytes and BytesN are already packed
        return values
    elif isinstance(values, Bitvector):
        as_integer = sum([values[i] << i for i in range(len(values))])
        return as_integer.to_bytes((values.length + 7) // 8, "little")
    //todo question asked about apaprently variable-len packing here
    elif isinstance(values, Bitlist):
        as_integer = sum([values[i] << i for i in range(len(values))])
        return as_integer.to_bytes((values.length + 7) // 8, "little")
    return b''.join([serialize_basic(value) for value in values])*/
  //Argument is either a List or BytesN. todo - specific type
  syntax Bytes ::= pack ( Value ) [function]
  rule pack(B:Bytes) => B

  //Version for lists
  syntax Bytes ::= pack ( list: TypedList, staticLen: Int, elemType: ElementType )

  //todo using StaticLEN here, python uses dynamic len. Static seems correct. Waiting answer on slack.
  rule pack(BL:BitList, StaticLEN, %bool) => to_bytes( toInt(BL, (StaticLEN +Int 7) /Int 8 *Int 8),
                                                       (StaticLEN +Int 7) /Int 8 )

  // Int lists will be padded to their static size later anyway. So it doesn't matter if LEN here is static or dynamic.
  rule pack(I:Int IL:IntList, StaticLEN, ElemType) => serialize_basic(I, ElemType) +Bytes pack(IL, StaticLEN -Int 1, ElemType)
  rule pack(.IntList, StaticLEN, ElemType) => serialize_basic(0, ElemType) +Bytes pack(.IntList, StaticLEN -Int 1, ElemType)
    requires StaticLEN >Int 0
  rule pack(.IntList, 0, _) => ""

/*
It is here that chunkification described in the dock of pack() happens.

def chunkify(bytez):
    # pad `bytez` to nearest 32-byte multiple
    bytez += b'\x00' * (-len(bytez) % 32)
    return [bytez[i:i + 32] for i in range(0, len(bytez), 32)]
*/
  syntax HashList ::= chunkify( Bytes )                               [function]
  rule chunkify(B) => chunkifyAux(padTo32(B))

  syntax Bytes ::= padTo32( Bytes )                                   [function]
  rule padTo32(BYTES) => BYTES +Bytes ("\x00" *Bytes ((lengthString(BYTES) +Int 31) /Int 32 -Int lengthString(BYTES)) )

  syntax HashList ::= chunkifyAux( Bytes )                           [function]
  rule chunkifyAux(BYTES) => substrString(BYTES, 0, 32) chunkifyAux(substrString(BYTES, 32, lengthString(BYTES)))
    requires lengthString(BYTES) >=Int 32

  rule chunkifyAux("") => .HashList

/*
ZERO_BYTES32 = b'\x00' * 32

zerohashes = [ZERO_BYTES32]
for layer in range(1, 100):
    zerohashes.append(hash(zerohashes[layer - 1] + zerohashes[layer - 1]))
*/
  syntax Hash ::= zerohashes ( Int )                                  [function]
  rule zerohashes(0) => {"\x00" *Bytes 32}:>String
  rule zerohashes(I) => hashConcat(zerohashes(I -Int 1), zerohashes(I -Int 1))
    requires I >Int 0

/*def merkleize_chunks(chunks, pad_to: int=1):
    count = len(chunks)
    depth = max(count - 1, 0).bit_length()
    max_depth = max(depth, (pad_to - 1).bit_length())
    tmp = [None for _ in range(max_depth + 1)]

    def merge(h, i):
        j = 0
        while True:
            if i & (1 << j) == 0:
                if i == count and j < depth:
                    h = hash(h + zerohashes[j])  # keep going if we are complementing the void to the next power of 2
                else:
                    break
            else:
                h = hash(tmp[j] + h)
            j += 1
        tmp[j] = h

    # merge in leaf by leaf.
    for i in range(count):
        merge(chunks[i], i)

    # complement with 0 if empty, or if not the right power of 2
    if 1 << depth != count:
        merge(zerohashes[0], count)

    # the next power of two may be smaller than the ultimate virtual size, complement with zero-hashes at each depth.
    for j in range(depth, max_depth):
        tmp[j + 1] = hash(tmp[j] + zerohashes[j])

    return tmp[max_depth]
*/
  syntax Hash ::= "merkleize_chunks" "(" HashList "," Int ")"        [function]
  rule merkleize_chunks(CHUNKS, PadTO)
       => merkleizeChunksLoop1(len(CHUNKS), //count
                               bit_length(maxInt(len(CHUNKS) -Int 1, 0)), //depth
                               maxInt(bit_length(maxInt(len(CHUNKS) -Int 1, 0)), bit_length(PadTO -Int 1)), //max_depth
                               CHUNKS,
                               0, .Map)

  /*    for i in range(count):
          merge(chunks[i], i)     */
  syntax Hash ::= merkleizeChunksLoop1(Int,       // count
                                       Int,       // depth
                                       Int,       // max_depth
                                       HashList, // chunks
                                       Int,       // i
                                       Map        // tmp
                                       )
  rule merkleizeChunksLoop1(COUNT, DEPTH, MaxDEPTH, (CH CHUNKS => CHUNKS), I => I +Int 1,
                            TMP => merkleMerge(CH, I, COUNT, DEPTH, TMP))

  rule merkleizeChunksLoop1(COUNT, DEPTH, MaxDEPTH, .HashList, I, TMP)
       => merkleizeChunksLoop2(DEPTH, MaxDEPTH,
                               #if (1 <<Int DEPTH =/=Int COUNT)
                                  #then merkleMerge(zerohashes(0), COUNT, COUNT, DEPTH, TMP) //merge(zerohashes[0], count)
                                  #else TMP
                               #fi)

/* for j in range(depth, max_depth):
      tmp[j + 1] = hash(tmp[j] + zerohashes[j])
*/
  syntax Hash ::= merkleizeChunksLoop2(Int, // j
                                       Int, // max_depth
                                       Map  //tmp
                                      )
  rule merkleizeChunksLoop2( J => J +Int 1, MaxDEPTH, TMP => TMP[J +Int 1 <- hashConcat({TMP[J]}:>Hash, zerohashes(J))] )
    requires J <Int MaxDEPTH

  //end of merkleize_chunks
  //return tmp[max_depth]
  rule merkleizeChunksLoop2( J, MaxDEPTH, TMP ) => TMP[MaxDEPTH]
    requires J >=Int MaxDEPTH

/*  Inner function in merkleize_chunks. Returns the new tmp.
    def merge(h, i):
        j = 0
        while True:
            if i & (1 << j) == 0:
                if i == count and j < depth:
                    h = hash(h + zerohashes[j])  # keep going if we are complementing the void to the next power of 2
                else:
                    break
            else:
                h = hash(tmp[j] + h)
            j += 1
        tmp[j] = h
*/
  syntax Map ::= merkleMerge( Hash, // h
                              Int,  // i
                              Int,  // count
                              Int,  // depth
                              Map   // tmp
                              )                                       [function]
  rule merkleMerge(H, I, COUNT, DEPTH, TMP) => merkleMergeLoop(H, I, COUNT, DEPTH, TMP, 0)

  syntax Map ::= merkleMergeLoop( Hash, // h
                                  Int,  // i
                                  Int,  // count
                                  Int,  // depth
                                  Map,  // tmp
                                  Int   // j
                                  )                                   [function]
  rule merkleMergeLoop(H => hashConcat(H, zerohashes(J)), I, COUNT, DEPTH, TMP, J => J +Int 1)
    requires I &Int (1 <<Int J) ==Int 0
     andBool I ==Int COUNT andBool J <Int DEPTH

  rule merkleMergeLoop(H, I, COUNT, DEPTH, TMP, J) => TMP[J <- H]
    requires I &Int (1 <<Int J) ==Int 0
     andBool notBool (I ==Int COUNT andBool J <Int DEPTH)

  rule merkleMergeLoop(H => hashConcat({TMP[J]}:>Bytes, H), I, COUNT, DEPTH, TMP, J => J +Int 1)
    requires notBool (I &Int (1 <<Int J) ==Int 0)

/* def is_bottom_layer_kind(typ: SSZType):
    return (
        isinstance(typ, BasicType) or
        (issubclass(typ, Elements) and isinstance(typ.elem_type, BasicType))
    )
*/
  syntax Bool ::= "is_bottom_layer_kind" "(" ValueOrList ")"          [function]
  rule is_bottom_layer_kind(_:BasicValue) => true
  rule is_bottom_layer_kind(_:Bytes48List) => true
  rule is_bottom_layer_kind(_:IntList) => true
  rule is_bottom_layer_kind(_:BitList) => true
  rule is_bottom_layer_kind(_:HashList) => true

  rule is_bottom_layer_kind(_) => false                               [owise]

/* def hash_tree_root(obj: SSZValue):
    if isinstance(obj, Series):
        if is_bottom_layer_kind(obj.type()):
            leaves = chunkify(pack(obj))
        else:
            leaves = [hash_tree_root(value) for value in obj]
    elif isinstance(obj, BasicValue):
        leaves = chunkify(serialize_basic(obj))
    else:
        raise Exception(f"Type not supported: {type(obj)}")

    if isinstance(obj, (List, Bytes, Bitlist)):
        return mix_in_length(merkleize_chunks(leaves, pad_to=chunk_count(obj.type())), len(obj))
    else:
        return merkleize_chunks(leaves)
*/
  syntax Hash ::= "hash_tree_root" "(" BytesOrContainer ")"           [function]
  rule hash_tree_root(VAL:Container) => hash_tree_root(VAL, %container)
  rule hash_tree_root(BYTES:Bytes) => hash_tree_root(BYTES, %bytes)

  syntax Hash ::= "hash_tree_root" "(" Value "," ElementType ")"      [function]
  rule hash_tree_root(VAL:BasicValue, ElemType) => hash_tree_root_part2_v2(chunkify(serialize_basic(VAL, ElemType)))

  //hash_tree_root branch 1.2, container types
  //leaves = [hash_tree_root(value) for value in obj]
  //-----------------------------------------------
  rule hash_tree_root(#Fork( P1, P2, P3 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3, %uint64) .HashList))

  rule hash_tree_root(#Checkpoint( P1, P2 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1, %uint64) hash_tree_root(P2) .HashList))

  rule hash_tree_root(#Validator( P1, P2, P3, P4, P5, P6, P7, P8 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3, %uint64)
          hash_tree_root(P4, %bool) hash_tree_root(P5, %uint64) hash_tree_root(P6, %uint64) hash_tree_root(P7, %uint64)
          hash_tree_root(P8, %uint64) .HashList))

  rule hash_tree_root(#Crosslink( P1, P2, P3, P4, P5 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1, %uint64) hash_tree_root(P2) hash_tree_root(P3, %uint64)
          hash_tree_root(P4, %uint64) hash_tree_root(P5) .HashList))

  rule hash_tree_root(#AttestationData( P1, P2, P3, P4 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3) hash_tree_root(P4)
          .HashList))

  rule hash_tree_root(#AttestationDataAndCustodyBit( P1, P2 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1) hash_tree_root(P2, %bool) .HashList))

  rule hash_tree_root(#IndexedAttestation( P1, P2, P3, P4 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %uint64, false)
          hash_tree_root_list(P2, MAX_VALIDATORS_PER_COMMITTEE, %uint64, false) hash_tree_root(P3) hash_tree_root(P4)
          .HashList))

  rule hash_tree_root(#PendingAttestation( P1, P2, P3, P4 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %bool, false)
          hash_tree_root(P2) hash_tree_root(P3, %uint64) hash_tree_root(P4, %uint64)
          .HashList))

  rule hash_tree_root(#Eth1Data( P1, P2, P3 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1) hash_tree_root(P2, %uint64) hash_tree_root(P3) .HashList))

  rule hash_tree_root(#HistoricalBatch( P1, P2 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root_list(P1, SLOTS_PER_HISTORICAL_ROOT, %bytes, true)
          hash_tree_root_list(P2, SLOTS_PER_HISTORICAL_ROOT, %bytes, true) .HashList))

  rule hash_tree_root(#DepositData( P1, P2, P3, P4 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3, %uint64) hash_tree_root(P4)
          .HashList))

  rule hash_tree_root(#CompactCommittee( P1, P2 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %bytes, false)
          hash_tree_root_list(P2, MAX_VALIDATORS_PER_COMMITTEE, %uint64, false) .HashList))

  rule hash_tree_root(#BeaconBlockHeader( P1, P2, P3, P4, P5 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1, %uint64) hash_tree_root(P2) hash_tree_root(P3) hash_tree_root(P4)
          hash_tree_root(P5) .HashList))

  rule hash_tree_root(#AttesterSlashing( P1, P2 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1) hash_tree_root(P2) .HashList))

  rule hash_tree_root(#Attestation( P1, P2, P3, P4 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %bool, false) hash_tree_root(P2)
          hash_tree_root_list(P3, MAX_VALIDATORS_PER_COMMITTEE, %bool, false) hash_tree_root(P4)
          .HashList))

  rule hash_tree_root(#Deposit( P1, P2 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root_list(P1, DEPOSIT_CONTRACT_TREE_DEPTH +Int 1, %bytes, true) hash_tree_root(P2) .HashList))

  rule hash_tree_root(#VoluntaryExit( P1, P2, P3 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1, %uint64) hash_tree_root(P2, %uint64) hash_tree_root(P3) .HashList))

  rule hash_tree_root(#Transfer( P1, P2, P3, P4, P5, P6, P7 ) #as VAL)
    => hash_tree_root_part2_v2((hash_tree_root(P1, %uint64) hash_tree_root(P2, %uint64) hash_tree_root(P3, %uint64)
          hash_tree_root(P4, %uint64) hash_tree_root(P5, %uint64) hash_tree_root(P6) hash_tree_root(P7) .HashList))


  syntax Hash ::= "hash_tree_root_list" "(" list: TypedList "," staticLen: Int "," elemType: ElementType "," fixedSize: Bool ")"

  //hash_tree_root for list of basic values
  //leaves = chunkify(pack(obj))
  //-----------------------------------------------
  rule hash_tree_root_list(LIST:BasicValueList, StaticLEN, ElemType, true)
    => hash_tree_root_part2_v2(chunkify(pack(LIST, StaticLEN, ElemType)))

  rule hash_tree_root_list(LIST:BasicValueList, StaticLEN, ElemType, false)
    => hash_tree_root_part2_v1(chunkify(pack(LIST, StaticLEN, ElemType)), StaticLEN, ElemType, len(LIST))

//fixme mix_in_length case for BytesN. BytesN = Vector[Byte, N], e.g. Bytes32, etc.
//fixme Bytes also is not BasicValue.
//byte array length = string length.

  //hash_tree_root branch 1.2, List/Vector types
  //leaves = [hash_tree_root(value) for value in obj]
  //padTo argument has to be supplied from the call context, it is the static list size.
  //-----------------------------------------------
  rule hash_tree_root_list(LIST:ContainerList, StaticLEN, ElemType, false)
    => hash_tree_root_part2_v1(chunkifyContainerList(LIST, 0), StaticLEN, ElemType, len(LIST))

  //Vector[Container] chunks must be padded to StaticLen.
  rule hash_tree_root_list(LIST:ContainerList, StaticLEN, _, true)
    => hash_tree_root_part2_v2(chunkifyContainerList(LIST, StaticLEN))

  syntax HashList ::= chunkifyContainerList( list: ContainerList , minLen: Int)          [function]

  rule chunkifyContainerList(V:AttesterSlashing L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Attestation L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Deposit L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:VoluntaryExit L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Transfer L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Crosslink L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Eth1Data L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:PendingAttestation L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(LIST, MinLen) => hash_tree_root(zerohashes(0)) chunkifyContainerList(LIST, MinLen -Int 1)
    requires len(LIST) ==Int 0 andBool MinLen >Int 0

  rule chunkifyContainerList(LIST, MinLen) => .HashList
    requires len(LIST) ==Int 0 andBool MinLen <=Int 0

/*  if isinstance(obj, (List, Bytes, Bitlist)):
        return mix_in_length(merkleize_chunks(leaves, pad_to=chunk_count(obj.type())), len(obj))
*/
  syntax Hash ::= "hash_tree_root_part2_v1" "(" leaves: HashList "," staticLen: Int "," elemType: ElementType ","
                                                dynamicLen: Int ")" [function]
  rule hash_tree_root_part2_v1(LEAVES, StaticLEN, ElemType, DynamicLen)
    => mix_in_length(merkleize_chunks(LEAVES, chunk_count(StaticLEN, ElemType)), DynamicLen)

/*  else: (from above)
        return merkleize_chunks(leaves)
*/
  syntax Hash ::= "hash_tree_root_part2_v2" "(" HashList ")" [function]
  rule hash_tree_root_part2_v2(LEAVES) => merkleize_chunks(LEAVES, 1)

/* def mix_in_length(root, length):
    return hash(root + length.to_bytes(32, 'little'))
*/
  syntax Hash ::= "mix_in_length" "(" Hash "," Int ")"                [function]
  rule mix_in_length(ROOT, LEN) => hashConcat(ROOT, to_bytes(LEN, 32))

/* def chunk_count(typ: SSZType) -> int:
    if isinstance(typ, BasicType):
        return 1
    elif issubclass(typ, Bits):
        return (typ.length + 255) // 256
    elif issubclass(typ, Elements):
        return (typ.length * item_length(typ.elem_type) + 31) // 32
    elif issubclass(typ, Container):
        return len(typ.get_fields())
    else:
        raise Exception(f"Type not supported: {typ}")
*/
  //cases BasicType and Container are not used by the spec. Only Bits and Elements. See call site.
  syntax Int ::= "chunk_count" "(" staticLen: Int "," elemType:ElementType ")" [function]
  rule chunk_count(StaticLEN, %bool) => (StaticLEN +Int 255) /Int 256 // elif issubclass(typ, Bits)
  rule chunk_count(StaticLEN, ElemType) => (StaticLEN *Int item_length(ElemType) +Int 31) /Int 32 // elif issubclass(typ, Elements)
    requires ElemType =/=K %bool

/* def item_length(typ: SSZType) -> int:
    if issubclass(typ, BasicValue):
        return typ.byte_len
    else:
        return 32
*/
  //returns the length in bytes of a list element. Argument in K is a list of BasicValue.
  syntax Int ::= "item_length" "(" ElementType ")"      [function]
  rule item_length(%uint8) => 1
  rule item_length(%uint16) => 2
  rule item_length(%uint32) => 4
  rule item_length(%uint64) => 8
  rule item_length(%uint128) => 16
  rule item_length(%uint256) => 32
  rule item_length(%container) => 32
  rule item_length(%bytes)     => 32

  syntax ElementType ::= "%bool" | "%uint8" | "%uint16" |"%uint32" | "%uint64" | "%uint128" | "%uint256"
                       | "%none"
                       | "%bytes" //todo should not be needed
                       | "%container"

endmodule
