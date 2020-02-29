module UINT64

imports INT

// bounded values
syntax UInt64 ::= #uint64(Int, Int, Int) // {min, max} bounds, value (64-bit)

// constructor
syntax UInt64 ::= ui(Int, Int, Int) [function]
rule ui(L, U, V) => #uint64(L, U, V) requires 0 <=Int L andBool L <=Int V andBool V <=Int U andBool U <Int 2 ^Int 64

// arithmetic
syntax UInt64 ::= left: // no functional, no hook
                UInt64 "*UInt64" UInt64 [function, left, klabel(_*UInt64_), smtlib(mulUInt64)]
              | UInt64 "/UInt64" UInt64 [function, left, klabel(_/UInt64_), smtlib(divUInt64)]
              > left:
                UInt64 "+UInt64" UInt64 [function, left, klabel(_+UInt64_), smtlib(addUInt64)]
              | UInt64 "-UInt64" UInt64 [function, left, klabel(_-UInt64_), smtlib(subUInt64)]

rule #uint64(L1, U1, V1) *UInt64 #uint64(L2, U2, V2) => ui(          L1 *Int L2,            U1 *Int U2,  V1 *Int V2)
rule #uint64(L1, U1, V1) /UInt64 #uint64(L2, U2, V2) => ui(          L1 /Int U2,            U1 /Int L2,  V1 /Int V2)
rule #uint64(L1, U1, V1) +UInt64 #uint64(L2, U2, V2) => ui(          L1 +Int L2,            U1 +Int U2,  V1 +Int V2)
rule #uint64(L1, U1, V1) -UInt64 #uint64(L2, U2, V2) => ui(maxInt(0, L1 -Int U2), maxInt(0, U1 -Int L2), V1 -Int V2) // requires V1 >=Int V2

// lift constants
syntax UInt64 ::= ci(Int) [function]
rule ci(V) => ui(V, V, V) requires V >=Int 0

// ensure bounds
syntax Int ::= ei(Int, Int, UInt64) [function]
rule ei(L, U, #uint64(L0, U0, V)) => V requires L <=Int L0 andBool U0 <=Int U

endmodule