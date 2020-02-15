module BOUNDS-CHECK-EXAMPLE

imports INT
imports LIST

// bounded values
syntax UInt ::= #uint(Int, Int, Int) // {min, max} bounds, value (64-bit)

// constructor
syntax UInt ::= ui(Int, Int, Int) [function]
rule ui(L, U, V) => #uint(L, U, V) requires 0 <=Int L andBool L <=Int V andBool V <=Int U andBool U <Int 2 ^Int 64

// arithmetic
syntax UInt ::= left: // no functional, no hook
                UInt "*UInt" UInt [function, left, klabel(_*UInt_), smtlib(mulUInt)]
              | UInt "/UInt" UInt [function, left, klabel(_/UInt_), smtlib(divUInt)]
              > left:
                UInt "+UInt" UInt [function, left, klabel(_+UInt_), smtlib(addUInt)]
              | UInt "-UInt" UInt [function, left, klabel(_-UInt_), smtlib(subUInt)]

rule #uint(L1, U1, V1) *UInt #uint(L2, U2, V2) => ui(          L1 *Int L2,            U1 *Int U2,  V1 *Int V2)
rule #uint(L1, U1, V1) /UInt #uint(L2, U2, V2) => ui(          L1 /Int U2,            U1 /Int L2,  V1 /Int V2)
rule #uint(L1, U1, V1) +UInt #uint(L2, U2, V2) => ui(          L1 +Int L2,            U1 +Int U2,  V1 +Int V2)
rule #uint(L1, U1, V1) -UInt #uint(L2, U2, V2) => ui(maxInt(0, L1 -Int U2), maxInt(0, U1 -Int L2), V1 -Int V2) // requires V1 >=Int V2

// lift constants
syntax UInt ::= ci(Int) [function]
rule ci(V) => ui(V, V, V) requires V >=Int 0

// ensure bounds
syntax UInt ::= ei(Int, Int, UInt) [function]
rule ei(L, U, #uint(L0, U0, _) #as V) => V requires L <=Int L0 andBool U0 <=Int U



// test

configuration <T>
  <k> $PGM:Cmds </k>
  <r> .List </r>
</T>

syntax Cmds ::= List{Cmd,""}
rule C:Cmd Cs:Cmds => C ~> Cs

syntax Cmd ::= run(Int, Int, Int)
rule <k> run(EffectiveBalance, TotalBalance, AttestingBalance) => . ... </k>
     <r> _:List (.List => ListItem(
            getBaseReward(EffectiveBalance, TotalBalance)                                       // #uint(11, 23, getBaseReward)
            *UInt ui(MAX_EFFECTIVE_BALANCE, MAX_ATTESTING_BALANCE, AttestingBalance)            // #uint(35, 41, AttestingBalance)
            /UInt ui(MAX_EFFECTIVE_BALANCE, TOTAL_ETHER_SUPPLY, TotalBalance)                   // #uint(35, 50, TotalBalance)
     )) </r>

syntax UInt ::= getBaseReward(Int, Int) [function]
rule getBaseReward(EffectiveBalance, TotalBalance)
  => ei(500, 3 *Int 10 ^Int 6,
        ui(MIN_DEPOSIT_AMOUNT, MAX_EFFECTIVE_BALANCE, EffectiveBalance)                         // #uint(30, 35, EffectiveBalance)
        *UInt ci(BASE_REWARD_FACTOR)                                                            // #uint( 7,  7, 64)
        /UInt ui(sqrt(MAX_EFFECTIVE_BALANCE), sqrt(TOTAL_ETHER_SUPPLY), sqrt(TotalBalance))     // #uint(18, 25, sqrt(TotalBalance))
        /UInt ci(BASE_REWARDS_PER_EPOCH)                                                        // #uint( 3,  3, 4)
     )

// constants

syntax Int ::= "BASE_REWARD_FACTOR"
rule BASE_REWARD_FACTOR => 2 ^Int 6                         [macro]

syntax Int ::= "BASE_REWARDS_PER_EPOCH"
rule BASE_REWARDS_PER_EPOCH => 4                            [macro]

syntax Int ::= "MIN_DEPOSIT_AMOUNT"
rule MIN_DEPOSIT_AMOUNT => 2 ^Int 0 *Int 10 ^Int 9          [macro]

syntax Int ::= "MAX_EFFECTIVE_BALANCE"
rule MAX_EFFECTIVE_BALANCE => 2 ^Int 5 *Int 10 ^Int 9       [macro]

syntax Int ::= "TOTAL_ETHER_SUPPLY"
rule TOTAL_ETHER_SUPPLY => 10 ^Int 6 *Int 10 ^Int 9         [macro]

syntax Int ::= "MAX_ATTESTING_BALANCE"
rule MAX_ATTESTING_BALANCE => 2 ^Int 42                     [macro]
// rule MAX_ATTESTING_BALANCE => TOTAL_ETHER_SUPPLY         [macro]

// sqrt

syntax Int ::= sqrt(Int) [function]
             | sqrt(Int, Int, Int) [function]
rule sqrt(N) => sqrt(N, N, (N +Int 1) /Int 2) requires N >=Int 0
rule sqrt(N, X, Y) => sqrt(N, Y, (Y +Int N /Int Y) /Int 2) requires Y <Int X
rule sqrt(N, X, Y) => X                                    requires Y >=Int X

endmodule
