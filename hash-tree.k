requires "types.k"

module HASH-TREE
  imports DOMAINS
  imports TYPES

  syntax Int ::= "BYTES_PER_CHUNK"
  rule BYTES_PER_CHUNK => 32                                  [macro]
  syntax Int ::= "BYTES_PER_LENGTH_OFFSET"
  rule BYTES_PER_LENGTH_OFFSET => 4                           [macro]
  syntax Int ::= "BITS_PER_BYTE"
  rule BITS_PER_BYTE => 8                                     [macro]

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
  rule serialize_basic(A:Int) => #Bytes(A, 8)
  rule serialize_basic(true)  => #Bytes(1, 1)
  rule serialize_basic(false) => #Bytes(0, 1)

/* Given ordered objects of the same basic type, serialize them, pack them into BYTES_PER_CHUNK-byte chunks,
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
  rule pack(BL:BitList) => #Bytes( toInt(BL, (JUSTIFICATION_BITS_LENGTH +Int 7) /Int 8 *Int 8),
                                   (JUSTIFICATION_BITS_LENGTH +Int 7) /Int 8)

  rule pack(VALUE:SSZValue) => serialize_basic(VALUE)

  // Int lists will be padded to their static size later anyway
  rule pack(I:Int IL:IntList) => serialize_basic(I) +Bytes pack(IL)
  rule pack(.IntList) => #Bytes(0, 0)

/*
It is here that chunkification described in the dock of pack() happens.

def chunkify(bytez):
    # pad `bytez` to nearest 32-byte multiple
    bytez += b'\x00' * (-len(bytez) % 32)
    return [bytez[i:i + 32] for i in range(0, len(bytez), 32)]
*/
  syntax IntList ::= chunkify( Bytes )                                [function]
  rule chunkify(B) => chunkifyAux(padTo32(B))

  syntax Bytes ::= padTo32( Bytes )                                   [function]
  rule padTo32(#Bytes(DATA, LEN)) => #Bytes(DATA <<Int ((LEN +Int 31) /Int 32 -Int LEN)  , (LEN +Int 31) /Int 32 )

  syntax IntList ::= chunkifyAux( Bytes )                             [function]
  rule chunkifyAux(#Bytes(DATA, LEN)) => chunkifyAux(#Bytes(DATA >>Int BYTES_PER_CHUNK, LEN -Int BYTES_PER_CHUNK))
                                         +IntList (DATA %Int (1 <<Int BYTES_PER_CHUNK) .IntList)
    requires LEN >Int BYTES_PER_CHUNK
  rule chunkifyAux(#Bytes(0, 0)) => .IntList

endmodule
