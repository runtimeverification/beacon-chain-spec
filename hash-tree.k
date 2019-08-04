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

/* Usage in KEVM: #parseHexBytes(Sha256(#unparseByteStack(WS:WordStack)))
  Judging by usage pattern, each char in the string is a byte.
*/
  syntax String ::= Sha256 ( String )                                 [function, hook(KRYPTO.sha256)]

/* def hash(data: bytes) -> Hash is SHA256.
*/
  syntax Hash ::= hash( Bytes )                                       [function]
  rule hash(BYTES) => Sha256(BYTES)

  // Aux functions
  //====================================================

  syntax Hash ::= hashConcat(Hash, Hash)                              [function]
  rule hashConcat(H1, H2) => hash(H1 +Bytes H2)

  // SSZ library functions
  //====================================================

//todo these integers might have different length??
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
  syntax Bytes ::= "serialize_basic" "(" BasicValue ")" [function]
  rule serialize_basic(A:Int) => Int2Bytes(A, 8)
  rule serialize_basic(true)  => "" +String chrChar(1 modInt (2 ^Int 8))
  rule serialize_basic(false) => "" +String chrChar(0 modInt (2 ^Int 8))

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
  syntax Bytes ::= pack ( Value ) [function]
  rule pack(B:Bytes) => B

  //Length is always JUSTIFICATION_BITS_LENGTH
  //not sure if this is little endian
  rule pack(BL:BitList) => Int2Bytes( toInt(BL, (JUSTIFICATION_BITS_LENGTH +Int 7) /Int 8 *Int 8),
                                      (JUSTIFICATION_BITS_LENGTH +Int 7) /Int 8 )

  rule pack(VALUE:BasicValue) => serialize_basic(VALUE)

  // Int lists will be padded to their static size later anyway
  rule pack(I:Int IL:IntList) => serialize_basic(I) +Bytes pack(IL)
  rule pack(.IntList) => ""

/*
It is here that chunkification described in the dock of pack() happens.

def chunkify(bytez):
    # pad `bytez` to nearest 32-byte multiple
    bytez += b'\x00' * (-len(bytez) % 32)
    return [bytez[i:i + 32] for i in range(0, len(bytez), 32)]
*/
  syntax ChunkList ::= chunkify( Bytes )                              [function]
  rule chunkify(B) => chunkifyAux(padTo32(B))

  syntax Bytes ::= padTo32( Bytes )                                   [function]
  rule padTo32(BYTES) => BYTES +Bytes ("\x00" *Bytes ((lengthString(BYTES) +Int 31) /Int 32 -Int lengthString(BYTES)) )

  syntax ChunkList ::= chunkifyAux( Bytes )                           [function]
  rule chunkifyAux(BYTES) => substrString(BYTES, 0, 32) , chunkifyAux(substrString(BYTES, 32, lengthString(BYTES)))
    requires lengthString(BYTES) >=Int 32

  rule chunkifyAux("") => .ChunkList

/*
ZERO_BYTES32 = b'\x00' * 32

zerohashes = [ZERO_BYTES32]
for layer in range(1, 100):
    zerohashes.append(hash(zerohashes[layer - 1] + zerohashes[layer - 1]))
*/
  syntax Hash ::= zerohashes ( Int )                                  [function]
  rule zerohashes(0) => "\x00" *Bytes 32
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
  syntax Hash ::= "merkleize_chunks" "(" ChunkList "," Int ")"        [function]
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
                                       ChunkList, // chunks
                                       Int,       // i
                                       Map        // tmp
                                       )
  rule merkleizeChunksLoop1(COUNT, DEPTH, MaxDEPTH, (CH, CHUNKS => CHUNKS), I => I +Int 1,
                            TMP => merkleMerge(CH, I, COUNT, DEPTH, TMP))

  rule merkleizeChunksLoop1(COUNT, DEPTH, MaxDEPTH, .ChunkList, I, TMP)
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
  syntax Bool ::= "is_bottom_layer_kind" "(" Value ")"                [function]
  rule is_bottom_layer_kind(_:BasicValue) => true
  rule is_bottom_layer_kind(_:Uint64List) => true
  rule is_bottom_layer_kind(_:Bytes32List) => true
  rule is_bottom_layer_kind(_:Bytes48List) => true
  rule is_bottom_layer_kind(_:IntList) => true
  rule is_bottom_layer_kind(_:BitList) => true
  rule is_bottom_layer_kind(_:HashList) => true

  rule is_bottom_layer_kind(_) => false                               [owise]

endmodule
