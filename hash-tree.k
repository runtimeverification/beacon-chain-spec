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
  syntax Bytes ::= "serialize_basic" "(" SSZValue ")" [function]
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
  //todo a more narrow type - Series??.
  syntax Bytes ::= pack ( KItem ) [function]
  rule pack(B:Bytes) => B

  //Length is always JUSTIFICATION_BITS_LENGTH
  //not sure if this is little endian
  rule pack(BL:BitList) => Int2Bytes( toInt(BL, (JUSTIFICATION_BITS_LENGTH +Int 7) /Int 8 *Int 8),
                                      (JUSTIFICATION_BITS_LENGTH +Int 7) /Int 8 )

  rule pack(VALUE:SSZValue) => serialize_basic(VALUE)

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

endmodule
