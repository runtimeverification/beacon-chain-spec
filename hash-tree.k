requires "types.k"

module HASH-TREE
  imports DOMAINS
  imports BYTES-HOOKED
  imports TYPES

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

/*def pack(values: Series):
    if isinstance(values, bytes):  # Bytes and BytesN are already packed
        return values
    elif isinstance(values, Bitvector):
        as_integer = sum([values[i] << i for i in range(len(values))])
        return as_integer.to_bytes((values.length + 7) // 8, "little")
    elif isinstance(values, Bitlist):
        as_integer = sum([values[i] << i for i in range(len(values))])
        return as_integer.to_bytes((values.length + 7) // 8, "little")
    # FIXME - may include any container type and possibly lists
    return b''.join([serialize_basic(value) for value in values])*/
  //todo a more narrow type
  syntax Bytes ::= pack ( KItem ) [function]
  rule pack(B:Bytes) => B

  //Length is always JUSTIFICATION_BITS_LENGTH
  //fixme continue - correct number of bits
  //rule pack(BL:BitList) => toInt(BL, JUSTIFICATION_BITS_LENGTH)


endmodule