requires "types.k"
requires "config.k"

module HASH-TREE
  imports DOMAINS
  imports TYPES
  imports CONFIG

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
    elif isinstance(values, Bitlist):
        as_integer = sum([values[i] << i for i in range(len(values))])
        return as_integer.to_bytes((values.length + 7) // 8, "little")
    return b''.join([serialize_basic(value) for value in values])*/
  //Version for byte array
  syntax Bytes ::= pack ( Bytes )                                     [function]
  rule pack(B:Bytes) => B

  //Version for lists
  syntax Bytes ::= pack ( list: ValueList, staticLen: Int, elemType: ElementType )

  //Using StaticLEN here. Python code above also uses static length in "values.length".
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
  syntax BytesList ::= chunkify( Bytes )                               [function]
  rule chunkify(B) => chunkifyAux(padTo32(B))

  syntax Bytes ::= padTo32( Bytes )                                   [function]
  rule padTo32(BYTES) => BYTES +Bytes ("\x00" *Bytes ((lengthString(BYTES) +Int 31) /Int 32 -Int lengthString(BYTES)) )

  syntax BytesList ::= chunkifyAux( Bytes )                           [function]
  rule chunkifyAux(BYTES) => substrString(BYTES, 0, 32) chunkifyAux(substrString(BYTES, 32, lengthString(BYTES)))
    requires lengthString(BYTES) >=Int 32

  rule chunkifyAux("") => .BytesList

/*
ZERO_BYTES32 = b'\x00' * 32

zerohashes = [ZERO_BYTES32]
for layer in range(1, 100):
    zerohashes.append(hash(zerohashes[layer - 1] + zerohashes[layer - 1]))
*/
  syntax Hash ::= zerohashes ( Int )                                  [function]
  rule zerohashes(0) => defaultHash()
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
  syntax Hash ::= "merkleize_chunks" "(" BytesList "," Int ")"        [function]
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
                                       BytesList, // chunks
                                       Int,       // i
                                       Map        // tmp
                                       )
  rule merkleizeChunksLoop1(COUNT, DEPTH, MaxDEPTH, (CH CHUNKS => CHUNKS), I => I +Int 1,
                            TMP => merkleMerge(CH, I, COUNT, DEPTH, TMP))

  rule merkleizeChunksLoop1(COUNT, DEPTH, MaxDEPTH, .BytesList, I, TMP)
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
  rule is_bottom_layer_kind(_:Bytes) => true
  rule is_bottom_layer_kind(_:IntList) => true
  rule is_bottom_layer_kind(_:BitList) => true

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
  rule hash_tree_root(VAL:Container) => hash_tree_root(VAL, %container, false)
  rule hash_tree_root(BYTES:Bytes) => hash_tree_root(BYTES, %bytes)

  syntax Hash ::= "hash_tree_root" "(" BasicValueOrBytes "," ElementType ")" [function]

  //hash_tree_root branch 2:
  // elif isinstance(obj, BasicValue):
  rule hash_tree_root(VAL:BasicValue, ElemType) => hash_tree_root_part2_v2(chunkify(serialize_basic(VAL, ElemType)))

  //hash_tree_root branch 1.1, case Bytes
  //leaves = chunkify(pack(obj))
  //Bytes static/dynamic length = string length
  rule hash_tree_root(VAL:Bytes, %bytes) => hash_tree_root_part2_v2(chunkify(pack(VAL)))

  //hash_tree_root branch 1.2, container types:
  //if isinstance(obj, Series):
  //  ... else:
  //leaves = [hash_tree_root(value) for value in obj]
  //version for containers. Has the option to remove last element, used by signing_root().
  //-----------------------------------------------
  syntax Hash ::= "hash_tree_root" "(" Container "," ElementType "," removeLast: Bool ")"      [function]

  rule hash_tree_root(#Fork( P1, P2, P3 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3, %uint64) .BytesList, RemLast))

  rule hash_tree_root(#Checkpoint( P1, P2 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1, %uint64) hash_tree_root(P2) .BytesList, RemLast))

  rule hash_tree_root(#Validator( P1, P2, P3, P4, P5, P6, P7, P8 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3, %uint64)
          hash_tree_root(P4, %bool) hash_tree_root(P5, %uint64) hash_tree_root(P6, %uint64) hash_tree_root(P7, %uint64)
          hash_tree_root(P8, %uint64) .BytesList, RemLast))

  rule hash_tree_root(#Crosslink( P1, P2, P3, P4, P5 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1, %uint64) hash_tree_root(P2) hash_tree_root(P3, %uint64)
          hash_tree_root(P4, %uint64) hash_tree_root(P5) .BytesList, RemLast))

  rule hash_tree_root(#AttestationData( P1, P2, P3, P4 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3) hash_tree_root(P4)
          .BytesList, RemLast))

  rule hash_tree_root(#AttestationDataAndCustodyBit( P1, P2 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1) hash_tree_root(P2, %bool) .BytesList, RemLast))

  rule hash_tree_root(#IndexedAttestation( P1, P2, P3, P4 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %uint64, false)
          hash_tree_root_list(P2, MAX_VALIDATORS_PER_COMMITTEE, %uint64, false) hash_tree_root(P3) hash_tree_root(P4)
          .BytesList, RemLast))

  rule hash_tree_root(#PendingAttestation( P1, P2, P3, P4 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %bool, false)
          hash_tree_root(P2) hash_tree_root(P3, %uint64) hash_tree_root(P4, %uint64)
          .BytesList, RemLast))

  rule hash_tree_root(#Eth1Data( P1, P2, P3 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1) hash_tree_root(P2, %uint64) hash_tree_root(P3) .BytesList, RemLast))

  rule hash_tree_root(#HistoricalBatch( P1, P2 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root_list(P1, SLOTS_PER_HISTORICAL_ROOT, %bytes, true)
          hash_tree_root_list(P2, SLOTS_PER_HISTORICAL_ROOT, %bytes, true) .BytesList, RemLast))

  rule hash_tree_root(#DepositData( P1, P2, P3, P4 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1) hash_tree_root(P2) hash_tree_root(P3, %uint64) hash_tree_root(P4)
          .BytesList, RemLast))

  rule hash_tree_root(#CompactCommittee( P1, P2 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %bytes, false)
          hash_tree_root_list(P2, MAX_VALIDATORS_PER_COMMITTEE, %uint64, false) .BytesList, RemLast))

  rule hash_tree_root(#BeaconBlockHeader( P1, P2, P3, P4, P5 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1, %uint64) hash_tree_root(P2) hash_tree_root(P3) hash_tree_root(P4)
          hash_tree_root(P5) .BytesList, RemLast))

  rule hash_tree_root(#ProposerSlashing( P1, P2, P3 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1, %uint64) hash_tree_root(P2) hash_tree_root(P3) .BytesList, RemLast))

  rule hash_tree_root(#AttesterSlashing( P1, P2 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1) hash_tree_root(P2) .BytesList, RemLast))

  rule hash_tree_root(#Attestation( P1, P2, P3, P4 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root_list(P1, MAX_VALIDATORS_PER_COMMITTEE, %bool, false) hash_tree_root(P2)
          hash_tree_root_list(P3, MAX_VALIDATORS_PER_COMMITTEE, %bool, false) hash_tree_root(P4)
          .BytesList, RemLast))

  rule hash_tree_root(#Deposit( P1, P2 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root_list(P1, DEPOSIT_CONTRACT_TREE_DEPTH +Int 1, %bytes, true)
          hash_tree_root(P2) .BytesList, RemLast))

  rule hash_tree_root(#VoluntaryExit( P1, P2, P3 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1, %uint64) hash_tree_root(P2, %uint64) hash_tree_root(P3)
          .BytesList, RemLast))

  rule hash_tree_root(#Transfer( P1, P2, P3, P4, P5, P6, P7 ) #as VAL, %container, RemLast)
    => hash_tree_root_part2_v2(removeLast(hash_tree_root(P1, %uint64) hash_tree_root(P2, %uint64) hash_tree_root(P3, %uint64)
          hash_tree_root(P4, %uint64) hash_tree_root(P5, %uint64) hash_tree_root(P6) hash_tree_root(P7) .BytesList, RemLast))

  syntax Hash ::= "hash_tree_root_list" "(" list: ValueList "," staticLen: Int "," elemType: ElementType "," fixedSize: Bool ")"

  //hash_tree_root branch 1.1, case list of basic values
  //leaves = chunkify(pack(obj))
  //-----------------------------------------------
  rule hash_tree_root_list(LIST:BasicValueList, StaticLEN, ElemType, true)
    => hash_tree_root_part2_v2(chunkify(pack(LIST, StaticLEN, ElemType)))

  rule hash_tree_root_list(LIST:BasicValueList, StaticLEN, ElemType, false)
    => hash_tree_root_part2_v1(chunkify(pack(LIST, StaticLEN, ElemType)), StaticLEN, ElemType, len(LIST))

  //hash_tree_root branch 1.2, List/Vector types
  //leaves = [hash_tree_root(value) for value in obj]
  //padTo argument has to be supplied from the call context, it is the static list size.
  //-----------------------------------------------
  rule hash_tree_root_list(LIST:BytesOrContainerList, StaticLEN, ElemType, false)
    => hash_tree_root_part2_v1(chunkifyContainerList(LIST, 0), StaticLEN, ElemType, len(LIST))

  //Vector[Container] chunks must be padded to StaticLen.
  rule hash_tree_root_list(LIST:BytesOrContainerList, StaticLEN, _, true)
    => hash_tree_root_part2_v2(chunkifyContainerList(LIST, StaticLEN))


  syntax BytesList ::= chunkifyContainerList( list: BytesOrContainerList , minLen: Int)          [function]

  rule chunkifyContainerList(V:Hash L:BytesList, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:ProposerSlashing L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:AttesterSlashing L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Attestation L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Deposit L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:DepositData L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:VoluntaryExit L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Transfer L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Validator L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Crosslink L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:Eth1Data L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:PendingAttestation L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(V:CompactCommittee L, MinLen)
    => hash_tree_root(V) chunkifyContainerList(L, MinLen -Int 1)

  rule chunkifyContainerList(LIST, MinLen) => hash_tree_root(defaultHash()) chunkifyContainerList(LIST, MinLen -Int 1)
    requires len(LIST) ==Int 0 andBool MinLen >Int 0

  rule chunkifyContainerList(LIST, MinLen) => .BytesList
    requires len(LIST) ==Int 0 andBool MinLen <=Int 0

/*  if isinstance(obj, (List, Bytes, Bitlist)):
        return mix_in_length(merkleize_chunks(leaves, pad_to=chunk_count(obj.type())), len(obj))
*/
  syntax Hash ::= "hash_tree_root_part2_v1" "(" leaves: BytesList "," staticLen: Int "," elemType: ElementType ","
                                                dynamicLen: Int ")" [function]
  rule hash_tree_root_part2_v1(LEAVES, StaticLEN, ElemType, DynamicLen)
    => mix_in_length(merkleize_chunks(LEAVES, chunk_count(StaticLEN, ElemType)), DynamicLen)

/*  else: (from above)
        return merkleize_chunks(leaves)
*/
  syntax Hash ::= "hash_tree_root_part2_v2" "(" BytesList ")" [function]
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

  syntax ElementType ::= "%bool" | "%uint8" | "%uint16" |"%uint32" | "%uint64" | "%uint128" | "%uint256"
                       | "%bytes"
                       | "%container"

  // hash_tree_root() - BeaconBlock, stored in <block> in configuration
  //====================================================
  syntax Hash ::= "hash_tree_root_block" "(" ")"                      [function]
  rule [[ hash_tree_root_block()
       => hash_tree_root_part2_v2(hash_tree_root(SLOT, %uint64) hash_tree_root(PARENTROOT) hash_tree_root(STATEROOT)
                                  hash_tree_root_blockBody() hash_tree_root(SIG) .BytesList) ]]
    <blockSlot> SLOT </blockSlot>
    <parent-root> PARENTROOT </parent-root>
    <state-root> STATEROOT </state-root>
    <signature> SIG </signature>

  syntax Hash ::= "hash_tree_root_blockBody" "(" ")"                  [function]
  rule [[ hash_tree_root_blockBody()
       => hash_tree_root_part2_v2(
            hash_tree_root(RANDAO)
            hash_tree_root(ETH1Data)
            hash_tree_root(GRAFFITI)
            hash_tree_root_list(mapToList(ProposerSlashingMAP, 0, .ProposerSlashingList),
                                MAX_PROPOSER_SLASHINGS, %container, false)
            hash_tree_root_list(AttesterSlashingLIST, MAX_ATTESTER_SLASHINGS, %container, false)
            hash_tree_root_list(AttestationLIST, MAX_ATTESTATIONS, %container, false)
            hash_tree_root_list(DepositLIST, MAX_DEPOSITS, %container, false)
            hash_tree_root_list(VoluntaryExitLIST, MAX_VOLUNTARY_EXITS, %container, false)
            hash_tree_root_list(TransferLIST, MAX_TRANSFERS, %container, false)
            .BytesList) ]]
    <randao-reveal> RANDAO </randao-reveal>
    <block-eth1-data> ETH1Data </block-eth1-data>
    <graffiti> GRAFFITI </graffiti>
    <proposer-slashings> ProposerSlashingMAP </proposer-slashings>
    <attester-slashings> AttesterSlashingLIST </attester-slashings>
    <attestations> AttestationLIST </attestations>
    <deposits> DepositLIST </deposits>
    <voluntary-exits> VoluntaryExitLIST </voluntary-exits>
    <transfers> TransferLIST </transfers>

  //Default value for BeaconBlockBody.
  syntax Hash ::= "hash_tree_root_blockBodyEmpty" "(" ")"             [function]
  rule hash_tree_root_blockBodyEmpty()
       => hash_tree_root_part2_v2(
            hash_tree_root(defaultBytes96())
            hash_tree_root(#Eth1Data(defaultHash(), 0, defaultHash()))
            hash_tree_root(defaultHash())
            hash_tree_root_list(.ProposerSlashingList, MAX_PROPOSER_SLASHINGS, %container, false)
            hash_tree_root_list(.AttesterSlashingList, MAX_ATTESTER_SLASHINGS, %container, false)
            hash_tree_root_list(.AttestationList, MAX_ATTESTATIONS, %container, false)
            hash_tree_root_list(.DepositList, MAX_DEPOSITS, %container, false)
            hash_tree_root_list(.VoluntaryExitList, MAX_VOLUNTARY_EXITS, %container, false)
            hash_tree_root_list(.TransferList, MAX_TRANSFERS, %container, false)
            .BytesList)

  // hash_tree_root() - BeaconState, stored in <state> in configuration
  //====================================================
  syntax Hash ::= "hash_tree_root_state" "(" ")"                      [function]
  rule [[ hash_tree_root_state()
       => hash_tree_root_part2_v2(
            hash_tree_root(GenesisTime, %uint64)
            hash_tree_root(Slot, %uint64)
            hash_tree_root(FORK)
            hash_tree_root(BLOCKHeader)
            hash_tree_root_list(mapToList(BlockRootsMAP, 0, .BytesList), SLOTS_PER_HISTORICAL_ROOT, %bytes, true)
            hash_tree_root_list(mapToList(StateRootsMAP, 0, .BytesList), SLOTS_PER_HISTORICAL_ROOT, %bytes, true)
            hash_tree_root_list(HistoricalRoots, HISTORICAL_ROOTS_LIMIT, %bytes, false)
            hash_tree_root(ETH1Data)
            hash_tree_root_list(ETH1DataVotes, SLOTS_PER_ETH1_VOTING_PERIOD, %container, false)
            hash_tree_root(ETH1DepositIndex, %uint64)
            hash_tree_root_list(mapToList(ValidatorsMAP, 0, .ValidatorList), VALIDATOR_REGISTRY_LIMIT, %container, false)
            hash_tree_root_list(mapToList(BalancesMAP, 0, .IntList), VALIDATOR_REGISTRY_LIMIT, %uint64, false)
            hash_tree_root(StartShard, %uint64)
            hash_tree_root_list(RandaoMixes, EPOCHS_PER_HISTORICAL_VECTOR, %bytes, true)
            hash_tree_root_list(ActiveIndexRoots, EPOCHS_PER_HISTORICAL_VECTOR, %bytes, true)
            hash_tree_root_list(CompactCommitteeRoots, EPOCHS_PER_HISTORICAL_VECTOR, %bytes, true)
            hash_tree_root_list(mapToList(SlashingsMAP, 0, .IntList), EPOCHS_PER_SLASHINGS_VECTOR, %uint64, true)
            hash_tree_root_list(PreviousEpochAttestations, MAX_ATTESTATIONS *Int SLOTS_PER_EPOCH, %container, false)
            hash_tree_root_list(CurrentEpochAttestations, MAX_ATTESTATIONS *Int SLOTS_PER_EPOCH, %container, false)
            hash_tree_root_list(mapToList(PreviousCrosslinksMAP, 0, .IntList), SHARD_COUNT, %uint64, true)
            hash_tree_root_list(mapToList(CurrentCrosslinksMAP, 0, .IntList), SHARD_COUNT, %uint64, true)
            hash_tree_root_list(JustificationBits, JUSTIFICATION_BITS_LENGTH, %bool, true)
            hash_tree_root(PreviousJustifiedCheckpoint)
            hash_tree_root(CurrentJustifiedCheckpoint)
            hash_tree_root(FinalizedCheckpoint)
            .BytesList) ]]
    <genesis-time> GenesisTime </genesis-time>
    <slot> Slot </slot>
    <fork> FORK </fork>
    <latest-block-header> BLOCKHeader </latest-block-header>
    <block-roots> BlockRootsMAP </block-roots>
    <state-roots> StateRootsMAP </state-roots>
    <historical-roots> HistoricalRoots </historical-roots>
    <eth1-data> ETH1Data </eth1-data>
    <eth1-data-votes> ETH1DataVotes </eth1-data-votes>
    <eth1-deposit-index> ETH1DepositIndex </eth1-deposit-index>
    <validators> ValidatorsMAP </validators>
    <balances> BalancesMAP </balances>
    <start-shard> StartShard </start-shard>
    <randao-mixes> RandaoMixes </randao-mixes>
    <active-index-roots> ActiveIndexRoots </active-index-roots>
    <compact-committees-roots> CompactCommitteeRoots </compact-committees-roots>
    <slashings> SlashingsMAP </slashings>
    <previous-epoch-attestations> PreviousEpochAttestations </previous-epoch-attestations>
    <current-epoch-attestations> CurrentEpochAttestations </current-epoch-attestations>
    <previous-crosslinks> PreviousCrosslinksMAP </previous-crosslinks>
    <current-crosslinks> CurrentCrosslinksMAP </current-crosslinks>
    <justification-bits> JustificationBits </justification-bits>
    <previous-justified-checkpoint> PreviousJustifiedCheckpoint </previous-justified-checkpoint>
    <current-justified-checkpoint> CurrentJustifiedCheckpoint </current-justified-checkpoint>
    <finalized-checkpoint> FinalizedCheckpoint </finalized-checkpoint>

  // signing_root() - Same as hash_tree_root(), but ignoring last field, when it is BLSSignature.
  //====================================================
/* def signing_root(obj: Container):
    # ignore last field
    fields = [field for field in obj][:-1]
    leaves = [hash_tree_root(f) for f in fields]
    return merkleize_chunks(chunkify(b''.join(leaves)))
*/
  syntax Hash ::= "signing_root" "(" val: Container ")"               [function]
  rule signing_root(VAL) => hash_tree_root(VAL, %container, true)

  // Utility functions
  //====================================================

  // If 2nd arg is false, return the list unchanged. Else remove last element.
  syntax BytesList ::= removeLast ( input: BytesList, removeLast: Bool ) [function]
  rule removeLast(LIST, false) => LIST
  rule removeLast(E1 E2 LIST:BytesList, true) => E1 removeLast(E2 LIST:BytesList, true)
  rule removeLast(_ .BytesList, true) => .BytesList

endmodule
