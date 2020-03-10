requires "constants-minimal.k"

module TYPES
  imports DOMAINS
  imports CONSTANTS

  // Basic Python (SSZ) types
  //====================================================
  syntax Bytes   ::= String | Bytes4 | Bytes8 | Bytes32 | Bytes48 | Bytes96
                   | BLSSignature | BLSPubkey | Domain | DomainType | Version
  syntax Bytes4  ::= String | DomainType | Version
  syntax Bytes4 ::= defaultBytes4()                                   [function]
  rule defaultBytes4() => {"\x00" *Bytes 4}:>String

  syntax Bytes8  ::= String | Domain

  syntax Bytes32 ::= String | Root
  syntax Bytes32 ::= defaultBytes32()                                 [function]
  rule defaultBytes32() => {"\x00" *Bytes 32}:>String

  syntax Root    ::= String
  syntax Root    ::= defaultRoot()                                       [function]
  rule defaultRoot() => {defaultBytes32()}:>String

  syntax Bytes48 ::= String | BLSPubkey

  syntax Bytes96 ::= String | BLSSignature
  syntax Bytes96 ::= defaultBytes96()                                 [function]
  rule defaultBytes96() => {"\x00" *Bytes 96}:>String

  syntax Version        ::= String      //a fork version number
  syntax DomainType     ::= String      //a domain type
  syntax Domain         ::= String      //a signature domain
  syntax BLSPubkey      ::= String      //a BLS12-381 public key
  syntax BLSSignature   ::= String      //a BLS12-381 signature
  syntax BLSSignature ::= defaultBLSSignature()                       [function]
  rule defaultBLSSignature() => {defaultBytes96()}:>String

  syntax Uint64  ::= Int

  syntax Bit     ::= Bool
  syntax BasicValue ::= Int | Uint64 | Bool | ValidatorIndex

  syntax Fork ::= ".Fork"
  syntax BlockHeader ::= ".BlockHeader" | BeaconBlockHeader
  syntax Eth1Data ::= ".Eth1Data"
  syntax Checkpoint ::= ".Checkpoint"

  // Custom types
  //====================================================
  syntax ValidatorIndex ::= Int | ".ValidatorIndex"     //a validator registry index

  // List types
  //====================================================
  syntax IntList ::= List{Int, ""}
  syntax BitList ::= List{Bit, ""}
  syntax BasicValueList ::= IntList | BitList

  syntax ProposerSlashingList ::= List{ProposerSlashing, ""}
  syntax AttesterSlashingList ::= List{AttesterSlashing, ""}
  syntax AttestationList ::= List{Attestation, ""}
  syntax DepositList ::= List{Deposit, ""}
  syntax DepositDataList ::= List{DepositData, ""}
  syntax SignedVoluntaryExitList ::= List{SignedVoluntaryExit, ""}
  syntax ValidatorList ::= List{Validator, ""}
  syntax Eth1DataList ::= List{Eth1Data, ""}
  syntax PendingAttestationList ::= List{PendingAttestation, ""}

  syntax ContainerList ::= ProposerSlashingList | AttesterSlashingList | AttestationList | DepositList | DepositDataList
       | SignedVoluntaryExitList | ValidatorList
       | Eth1DataList | PendingAttestationList

  syntax BytesList ::= List{Bytes, ""}

  syntax BytesOrContainerList ::= BytesList | ContainerList
  syntax ValueList ::= BasicValueList | BytesOrContainerList

  // Containers
  //====================================================
  /*
class Fork(Container):
    previous_version: Version
    current_version: Version
    epoch: Epoch  # Epoch of latest fork
  */
  syntax Fork ::= #Fork( Version, Version, Int ) [klabel(#Fork), symbol]

  syntax Version ::= Fork "." "previousVersion"                       [function]
  rule #Fork(PV,_,_).previousVersion => PV
  syntax Version ::= Fork "." "currentVersion"                        [function]
  rule #Fork(_,CV,_).currentVersion => CV
  syntax Int ::= Fork "." "epoch"                                     [function]
  rule #Fork(_,_,EPOCH).epoch => EPOCH

  /*
class Checkpoint(Container):
    epoch: Epoch
    root: Root
  */
  syntax Checkpoint ::= #Checkpoint( Int, Root ) [klabel(#Checkpoint), symbol]

  syntax Int ::= Checkpoint "." "epoch"                               [function]
  rule #Checkpoint(EPOCH,_).epoch => EPOCH
  syntax Root ::= Checkpoint "." "root"                               [function]
  rule #Checkpoint(_,ROOT).root => ROOT

  syntax Checkpoint ::= defaultCheckpoint()                           [function]
  rule defaultCheckpoint() => #Checkpoint(0, defaultRoot())

  /*
class Validator(Container):
    pubkey: BLSPubkey
    withdrawal_credentials: Bytes32  # Commitment to pubkey for withdrawals
    effective_balance: Gwei  # Balance at stake
    slashed: boolean
    # Status epochs
    activation_eligibility_epoch: Epoch  # When criteria for activation were met
    activation_epoch: Epoch
    exit_epoch: Epoch
    withdrawable_epoch: Epoch  # When validator can withdraw funds
  */
  syntax Validator ::= #Validator( pubkey: BLSPubkey,
                                   withdrawalCredentials: Bytes32,
                                   effectiveBalance: Int,
                                   slashed: Bool,
                                   activationEligibilityEpoch: Int,
                                   activationEpoch: Int,
                                   exitEpoch: Int,
                                   withdrawableEpoch: Int
                                 ) [klabel(#Validator), symbol]

  syntax BLSPubkey ::= Validator "." "pubkey"                         [function]
  rule #Validator(PK, _,_,_,_,_,_,_).pubkey => PK
  syntax Bytes32   ::= Validator "." "withdrawalCredentials"          [function]
  rule #Validator(_, HASH, _,_,_,_,_,_).withdrawalCredentials => HASH
  syntax Int      ::= Validator "." "effectiveBalance"                [function]
  rule #Validator(_,_, EffBal, _,_,_,_,_).effectiveBalance => EffBal
  syntax Bool      ::= Validator "." "slashed"                        [function]
  rule #Validator(_,_,_, SLASHED, _,_,_,_).slashed => SLASHED
  syntax Int       ::= Validator "." "activationEligibilityEpoch"     [function]
  rule #Validator(_,_,_,_, ActEligEpoch, _,_,_).activationEligibilityEpoch => ActEligEpoch
  syntax Int       ::= Validator "." "activationEpoch"                [function]
  rule #Validator(_,_,_,_,_, ActivationEpoch, _,_).activationEpoch => ActivationEpoch
  syntax Int       ::= Validator "." "exitEpoch"                      [function]
  rule #Validator(_,_,_,_,_,_, ExitEpoch,_).exitEpoch => ExitEpoch
  syntax Int       ::= Validator "." "withdrawableEpoch"              [function]
  rule #Validator(_,_,_,_,_,_,_, WithdrawEpoch).withdrawableEpoch => WithdrawEpoch

  /*
class AttestationData(Container):
    slot: Slot
    index: CommitteeIndex
    # LMD GHOST vote
    beacon_block_root: Root
    # FFG vote
    source: Checkpoint
    target: Checkpoint
  */
  syntax AttestationData ::= #AttestationData(Int, Int, Root, Checkpoint, Checkpoint ) [klabel(#AttestationData), symbol]

  syntax Int ::= AttestationData "." "_slot"                          [function]
  rule #AttestationData(SLOT,_,_,_,_)._slot => SLOT
  syntax Int ::= AttestationData "." "index"                          [function]
  rule #AttestationData(_,INDEX,_,_,_).index => INDEX
  syntax Root ::= AttestationData "." "beaconBlockRoot"               [function]
  rule #AttestationData(_,_,ROOT,_,_).beaconBlockRoot => ROOT
  syntax Checkpoint ::= AttestationData "." "source"                  [function]
  rule #AttestationData(_,_,_,CP,_).source => CP
  syntax Checkpoint ::= AttestationData "." "target"                  [function]
  rule #AttestationData(_,_,_,_,CP).target => CP

  /*
class IndexedAttestation(Container):
    attesting_indices: List[ValidatorIndex, MAX_VALIDATORS_PER_COMMITTEE]
    data: AttestationData
    signature: BLSSignature
  */
  syntax IndexedAttestation ::= #IndexedAttestation( IntList, AttestationData, BLSSignature ) [klabel(#IndexedAttestation), symbol]

  syntax IntList ::= IndexedAttestation "." "attesting_indices"       [function]
  rule #IndexedAttestation( IL0, _, _ ).attesting_indices => IL0
  syntax AttestationData ::= IndexedAttestation "." "data"            [function]
  rule #IndexedAttestation( _,DATA ,_ ).data => DATA

  /*
class PendingAttestation(Container):
    aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
    data: AttestationData
    inclusion_delay: Slot
    proposer_index: ValidatorIndex
  */
  syntax PendingAttestation ::= #PendingAttestation( BitList, AttestationData, Int, ValidatorIndex ) [klabel(#PendingAttestation), symbol]

  syntax BitList ::= PendingAttestation "." "aggregationBits"         [function]
  rule #PendingAttestation(BITS,_,_,_).aggregationBits => BITS
  syntax AttestationData ::= PendingAttestation "." "data"            [function]
  rule #PendingAttestation(_,DATA,_,_).data => DATA
  syntax Int ::= PendingAttestation "." "inclusionDelay"              [function]
  rule #PendingAttestation(_,_,SLOT,_).inclusionDelay => SLOT
  syntax ValidatorIndex ::= PendingAttestation "." "proposerIndex"    [function]
  rule #PendingAttestation(_,_,_,VI).proposerIndex => VI

  /*
class Eth1Data(Container):
    deposit_root: Root
    deposit_count: uint64
    block_hash: Bytes32
  */
  syntax Eth1Data ::= #Eth1Data( Root, Int, Bytes32 ) [klabel(#Eth1Data), symbol]

  syntax Root ::= Eth1Data "." "deposit_root" [function]
  rule #Eth1Data(DROOT, _, _).deposit_root => DROOT
  syntax Int ::= Eth1Data "." "deposit_count" [function]
  rule #Eth1Data(_, DCOUNT, _).deposit_count => DCOUNT
  syntax Bytes32 ::= Eth1Data "." "block_hash" [function]
  rule #Eth1Data(_, _, BHASH).block_hash => BHASH

/*
class Eth1Block(Container):
    timestamp: uint64
    # All other eth1 block fields
*/
  syntax Eth1Block ::= #Eth1Block( Int ) [klabel(#Eth1Block), symbol]
  /*
class HistoricalBatch(Container):
    block_roots: Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
    state_roots: Vector[Root, SLOTS_PER_HISTORICAL_ROOT]
  */
  syntax HistoricalBatch ::= #HistoricalBatch( BytesList, BytesList ) [klabel(#HistoricalBatch), symbol]
 /*   
class DepositMessage(Container):
    pubkey: BLSPubkey
    withdrawal_credentials: Bytes32
    amount: Gwei
  */
  syntax DepositMessage ::= #DepositMessage( BLSPubkey, Bytes32, Int ) [klabel(#DepositMessage), symbol]

  syntax BLSPubkey  ::= DepositMessage "." "pubkey"                      [function]
  rule #DepositMessage( PUBKEY, _,_).pubkey => PUBKEY
  syntax Bytes32    ::= DepositMessage "." "withdrawal_credentials"      [function]
  rule #DepositMessage( _, WC, _).withdrawal_credentials => WC
  syntax Int        ::= DepositMessage "." "amount"                      [function]
  rule #DepositMessage( _,_, AMOUNT).amount => AMOUNT
  
  /*
class DepositData(Container):
    pubkey: BLSPubkey
    withdrawal_credentials: Bytes32
    amount: Gwei
    signature: BLSSignature
  */
  syntax DepositData ::= #DepositData( BLSPubkey, Bytes32, Int, BLSSignature ) [klabel(#DepositData), symbol]

  syntax BLSPubkey  ::= DepositData "." "pubkey"                      [function]
  rule #DepositData( PUBKEY, _,_,_ ).pubkey => PUBKEY
  syntax Bytes32    ::= DepositData "." "withdrawal_credentials"      [function]
  rule #DepositData( _, WC, _,_ ).withdrawal_credentials => WC
  syntax Int        ::= DepositData "." "amount"                      [function]
  rule #DepositData( _,_, AMOUNT, _ ).amount => AMOUNT

  /*
class BeaconBlockHeader(Container):
    slot: Slot
    parent_root: Root
    state_root: Root
    body_root: Root
  */
  syntax BeaconBlockHeader ::= #BeaconBlockHeader( Int, Root, Root, Root ) [klabel(#BeaconBlockHeader), symbol]

  //Cannot use "slot", conflicts with cell <slot>
  syntax Int  ::= BeaconBlockHeader "." "_slot"                       [function]
  rule #BeaconBlockHeader(SLOT, _,_,_)._slot => SLOT
  syntax Root ::= BeaconBlockHeader "." "parent_root"                 [function]
  rule #BeaconBlockHeader(_,ParentRoot, _,_).parent_root => ParentRoot
  syntax Root ::= BeaconBlockHeader "." "state_root"                  [function]
  rule #BeaconBlockHeader(_,_,StateRoot, _).state_root => StateRoot
  syntax Root ::= BeaconBlockHeader "." "body_root"                   [function]
  rule #BeaconBlockHeader(_,_,_,BodyRoot).body_root => BodyRoot
/*
class SigningRoot(Container):
    object_root: Root
    domain: Domain
*/
  syntax SigningRoot ::= #SigningRoot ( Root, Domain ) [klabel(#SigningRoot), symbol]

  syntax Root  ::= SigningRoot "." "object_root"                      [function]
  rule #SigningRoot(ROOT,_).object_root => ROOT
  syntax Domain ::= SigningRoot "." "domain"                          [function]
  rule #SigningRoot(_,DOMAIN).domain => DOMAIN

/*
class SignedVoluntaryExit(Container):
    message: VoluntaryExit
    signature: BLSSignature
*/
  syntax SignedVoluntaryExit ::= #SignedVoluntaryExit ( VoluntaryExit, BLSSignature ) [klabel(#SignedVoluntaryExit), symbol]

  syntax VoluntaryExit  ::= SignedVoluntaryExit "." "message"                   [function]
  rule #SignedVoluntaryExit(EXIT,_).message => EXIT

/*
class SignedBeaconBlock(Container):
    message: BeaconBlock
    signature: BLSSignature
*/
  syntax SignedBeaconBlock ::= #SignedBeaconBlock ( BeaconBlock, BLSSignature ) [klabel(#SignedBeaconBlock), symbol]

  syntax BeaconBlock  ::= SignedBeaconBlock "." "message"                      [function]
  rule #SignedBeaconBlock(BLOCK,_).message => BLOCK

/*
class SignedBeaconBlockHeader(Container):
    message: BeaconBlockHeader
    signature: BLSSignature
*/
  syntax SignedBeaconBlockHeader ::= #SignedBeaconBlockHeader ( BeaconBlockHeader, BLSSignature ) [klabel(#SignedBeaconBlockHeader), symbol]

  syntax BeaconBlockHeader  ::= SignedBeaconBlockHeader "." "message"           [function]
  rule #SignedBeaconBlockHeader(BLOCKH,_).message => BLOCKH

/* class ProposerSlashing(Container):
    proposer_index: ValidatorIndex
    signed_header_1: SignedBeaconBlockHeader
    signed_header_2: SignedBeaconBlockHeader
*/
syntax ProposerSlashing ::= #ProposerSlashing( proposerIndex: ValidatorIndex,
                                               signedHeader1: SignedBeaconBlockHeader, signedHeader2: SignedBeaconBlockHeader ) [klabel(#ProposerSlashing), symbol]

  /*
class AttesterSlashing(Container):
    attestation_1: IndexedAttestation
    attestation_2: IndexedAttestation
  */
  syntax AttesterSlashing ::= #AttesterSlashing( IndexedAttestation, IndexedAttestation ) [klabel(#AttesterSlashing), symbol]

  /*
class Attestation(Container):
    aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
    data: AttestationData
    signature: BLSSignature
  */
  syntax Attestation ::= #Attestation( BitList, AttestationData, BLSSignature ) [klabel(#Attestation), symbol]

  syntax BitList ::= Attestation "." "aggregation_bits"               [function]
  rule #Attestation(AggrBITS, _,_).aggregation_bits => AggrBITS
  syntax AttestationData ::= Attestation "." "_data"                  [function]
  rule #Attestation(_, AttDATA,_)._data => AttDATA

  /*
class Deposit(Container):
    proof: Vector[Bytes32, DEPOSIT_CONTRACT_TREE_DEPTH + 1]  # Merkle path to deposit data list root
    data: DepositData
  */
  syntax Deposit ::= #Deposit( BytesList, DepositData ) [klabel(#Deposit), symbol]

  syntax BytesList ::= Deposit "." "proof"                           [function]
  rule #Deposit(PROOF, _).proof => PROOF
  syntax DepositData ::= Deposit "." "data"                          [function]
  rule #Deposit(_, DATA).data => DATA


  /*
class VoluntaryExit(Container):
    epoch: Epoch  # Earliest epoch when voluntary exit can be processed
    validator_index: ValidatorIndex
  */
  syntax VoluntaryExit ::= #VoluntaryExit( Int, ValidatorIndex ) [klabel(#VoluntaryExit), symbol]

/*class BeaconBlockBody(Container):
    randao_reveal: BLSSignature
    eth1_data: Eth1Data  # Eth1 data vote
    graffiti: Bytes32  # Arbitrary data
    # Operations
    proposer_slashings: List[ProposerSlashing, MAX_PROPOSER_SLASHINGS]
    attester_slashings: List[AttesterSlashing, MAX_ATTESTER_SLASHINGS]
    attestations: List[Attestation, MAX_ATTESTATIONS]
    deposits: List[Deposit, MAX_DEPOSITS]
    voluntary_exits: List[SignedVoluntaryExit, MAX_VOLUNTARY_EXITS]
*/
  syntax BeaconBlockBody ::= #BeaconBlockBody(
                                randaoReveal: BLSSignature,
                                eth1Data: Eth1Data,
                                graffiti: Bytes32,
                                proposerSlashings: ProposerSlashingList,
                                attesterSlashings: AttesterSlashingList,
                                attestations: AttestationList,
                                deposits: DepositList,
                                voluntaryExits: SignedVoluntaryExitList
                             )                                [klabel(#BeaconBlockBody), symbol]
  syntax BLSSignature            ::= BeaconBlockBody "." "randaoReveal"      [function]
  rule  #BeaconBlockBody(RR,_,_,_,_,_,_,_).randaoReveal => RR
  syntax Eth1Data                ::= BeaconBlockBody "." "eth1Data"          [function]
  rule  #BeaconBlockBody(_,E1D,_,_,_,_,_,_).eth1Data => E1D
  syntax ProposerSlashingList    ::= BeaconBlockBody "." "proposerSlashings" [function]
  rule  #BeaconBlockBody(_,_,_,PS,_,_,_,_).proposerSlashings => PS
  syntax AttesterSlashingList    ::= BeaconBlockBody "." "attesterSlashings" [function]
  rule  #BeaconBlockBody(_,_,_,_, AS,_,_,_).attesterSlashings => AS
  syntax AttestationList         ::= BeaconBlockBody "." "attestations"      [function]
  rule  #BeaconBlockBody(_,_,_,_,_, ATT,_,_).attestations => ATT
  syntax DepositList             ::= BeaconBlockBody "." "deposits"          [function]
  rule  #BeaconBlockBody(_,_,_,_,_,_, DEP,_).deposits => DEP
  syntax SignedVoluntaryExitList ::= BeaconBlockBody "." "voluntaryExits"    [function]
  rule  #BeaconBlockBody(_,_,_,_,_,_,_, VEX).voluntaryExits => VEX

  syntax BeaconBlockBody ::= defaultBeaconBlockBody()                 [function]
  rule defaultBeaconBlockBody() => #BeaconBlockBody(
                                defaultBLSSignature(), #Eth1Data(defaultRoot(), 0, defaultRoot()), defaultBytes32(),
                                .ProposerSlashingList, .AttesterSlashingList, .AttestationList,
                                .DepositList, .SignedVoluntaryExitList
                             )

/*class BeaconBlock(Container):
    slot: Slot
    parent_root: Root
    state_root: Root
    body: BeaconBlockBody*/
  syntax BeaconBlock ::= #BeaconBlock(
                            blockSlot: Int,
                            parentRoot: Root,
                            stateRoot: Root,
                            body: BeaconBlockBody
                         )                                    [klabel(#BeaconBlock), symbol]
  syntax Int              ::= BeaconBlock "." "_slot"                     [function]
  rule  #BeaconBlock(SLOT, _,_,_)._slot => SLOT
  syntax Root             ::= BeaconBlock "." "parentRoot"                [function]
  rule  #BeaconBlock(_, PR, _,_).parentRoot => PR
  syntax Root             ::= BeaconBlock "." "stateRoot"                 [function]
  rule  #BeaconBlock(_,_, SR, _).stateRoot => SR
  syntax BeaconBlockBody  ::= BeaconBlock "." "body"                      [function]
  rule  #BeaconBlock(_,_,_, BODY).body => BODY

/*class AggregateAndProof(Container):
    aggregator_index: ValidatorIndex
    aggregate: Attestation
    selection_proof: BLSSignature*/
  syntax AggregateAndProof ::= #AggregateAndProof(
                               index: ValidatorIndex,
                               aggregate: Attestation,
                               selectionProof: BLSSignature
                               )                              [klabel(#AggregateAndProof), symbol]

  syntax ValidatorIndex ::= AggregateAndProof "." "aggregatorIndex"      [function]
  rule #AggregateAndProof(INDEX,_,_) => INDEX
  syntax Attestation ::= AggregateAndProof "." "aggregate"               [function]
  rule #AggregateAndProof(_,AG,_) => AG
  syntax BLSSignature ::= AggregateAndProof "." "selectionProof"         [function]
  rule #AggregateAndProof(_,_,SP) => SP

/*
class SignedAggregateAndProof(Container):
    message: AggregateAndProof
    signature: BLSSignature
*/
  syntax SignedAggregateAndProof ::= #SignedAggregateAndProof(
                                     message: AggregateAndProof,
                                     signature: BLSSignature
                                     )                              [klabel(#SignedAggregateAndProof), symbol]


  // The return type of get_attestation_deltas
  syntax MapMapPair ::= #mapMapPair(Map, Map)

  syntax Map ::= MapMapPair "." "map1" [function]
  rule  #mapMapPair(MAP,_).map1 => MAP
  syntax Map ::= MapMapPair "." "map2" [function]
  rule  #mapMapPair(_,MAP).map2 => MAP

  // An argument type of get_domain
  syntax OptionInt ::= #None() | #Some(Int)

  syntax Bool ::= isNone(OptionInt) [function]
  rule isNone(#None()) => true
  rule isNone(#Some(_)) => false

  syntax Int ::= intOf(OptionInt) [function]
  rule intOf(#Some(I)) => I

  // An argument type of compute_domain
  syntax OptionVersion ::= #NoneVers() | #SomeVers(Version)

  syntax Bool ::= isNone(OptionVersion) [function]
  rule isNone(#NoneVers()) => true
  rule isNone(#SomeVers(_)) => false

  syntax Version ::= versOf(OptionVersion) [function]
  rule versOf(#SomeVers(I)) => I

  syntax Container ::= Fork | Checkpoint | Validator | AttestationData | SigningRoot
                     | IndexedAttestation | PendingAttestation | Eth1Data | HistoricalBatch | DepositData
                     | BeaconBlockHeader | ProposerSlashing | AttesterSlashing | Attestation | Deposit
                     | VoluntaryExit | BeaconBlockBody | BeaconBlock | AggregateAndProof | DepositMessage
                     | SignedVoluntaryExit | SignedBeaconBlock | SignedBeaconBlockHeader | Eth1Block

  //ValueList are not Value, because it needs separate implementation for hash_tree_root
  //In ETH-2 specs, Bytes is of type Elements & Series, not BasicValue. All Bytes usages are fixed size, e.g. BytesN.
  syntax BytesOrContainer ::= Bytes | Container
  syntax BasicValueOrBytes ::= BasicValue | Bytes

  syntax Value ::= BasicValue | BytesOrContainer
  syntax ValueOrList ::= Value | ValueList

  // Type conversion functions
  //====================================================

/*    def as_bytes(Bits):
        as_bytearray = [0] * ((len(self) + 7) // 8)
        for i in range(len(self)):
            as_bytearray[i // 8] |= int(self[i]) << (i % 8)
        return bytes(as_bytearray)  */
  syntax Bytes ::= "as_bytes" "(" BitList ")"                         [function]
                 | "as_bytes" "(" bits: BitList "," asBytearray: List "," i: Int ")" [function]
  rule as_bytes(BL) => as_bytes(BL, initBuiltinListOfInt((len(BL) +Int 7) /Int 8), 0)
  rule as_bytes(BIT BL => BL,
                AsBytearray => AsBytearray[ I /Int 8 <- {AsBytearray[I /Int 8]}:>Int |Int (toInt(BIT) <<Int (I %Int 8)) ],
                I => I +Int 1)
  rule as_bytes(.BitList, ListItem(ELEM) AsBytearray, I) => chrChar(ELEM) +Bytes as_bytes(.BitList, AsBytearray, I)
  rule as_bytes(.BitList, .List, _) => ""

  syntax Int ::= toInt( Bool )                                        [function]
  rule toInt(B:Bool) => #if B #then 1 #else 0 #fi

  syntax List ::= initBuiltinListOfInt ( Int )                        [function]
  rule initBuiltinListOfInt(SIZE) => ListItem(0) initBuiltinListOfInt(SIZE -Int 1)
    requires SIZE >Int 0
  rule initBuiltinListOfInt(0) => .List

/* NOTE: this implementation is LITTLE ENDIAN, as expected by Beacon Chain spec everywhere.

Equivalent of python n.to_bytes(len, 'little')
  and int_to_bytes(n, length)
*/
  syntax Bytes ::= "to_bytes" "(" n: Int "," length: Int ")"          [function]
  rule to_bytes(N, LEN) => chrChar(N %Int 256) +Bytes to_bytes(N /Int 256, LEN -Int 1)
    requires LEN >Int 0
  rule to_bytes(0, 0) => ""

/*
def bytes_to_int(data: bytes) -> uint64:
    """
    Return the integer deserialization of ``data``.
    """
    return int.from_bytes(data, ENDIANNESS)
*/
  syntax Int ::= "bytes_to_int" "(" Bytes ")" [function]
  rule bytes_to_int(BYTES) => bytes_to_int(substrString(BYTES, 1, lengthString(BYTES))) *Int 256
                              +Int ordChar(substrString(BYTES, 0, 1))
    requires BYTES =/=String ""
  rule bytes_to_int("") => 0

  // Python framework functions
  //====================================================

  syntax Int ::= "bit_length" "(" Int ")"                             [function]
  rule bit_length(A) => log2Int(absInt(A)) +Int 1
    requires A =/=Int 0
  rule bit_length(0) => 0

  syntax Int ::= maxAux ( IntList )       [function, klabel(maxAux)]
               | maxAux ( IntList , Int ) [function, klabel(maxAux2)]
  rule maxAux( I:Int IL ) => maxAux(IL, I)
  rule maxAux(I IL => IL, MAX => #if I <Int MAX #then MAX #else I #fi )
  rule maxAux(.IntList, MAX) => MAX

  syntax IntList ::= sortIntList(IntList)                             [function]
  rule sortIntList(I IL) => #fun(MIN => MIN sortIntList(listExcept(I IL, MIN)))(minIndex(IL, I))
  rule sortIntList(.IntList) => .IntList

  syntax IntList ::= sortUniqueIntList(IntList)                       [function]
  rule sortUniqueIntList(I IL) => #fun(MIN => MIN sortUniqueIntList(listExcept(I IL, MIN)))(strictlyMinIndex(IL, I))
  rule sortUniqueIntList(.IntList) => .IntList


  syntax Int ::= minIndex(IntList, Int)                               [function]
  rule minIndex(I IL => IL, M => #if I <Int M #then I #else M #fi)
  rule minIndex(.IntList, M) => M

  syntax Int ::= strictlyMinIndex(IntList, Int)                       [function]
  rule strictlyMinIndex(I IL, M) => I requires I <Int M
  rule strictlyMinIndex(I IL, M) => M requires M <Int I
  rule strictlyMinIndex(.IntList, M) => M

  syntax Bool ::= contains( Int, IntList )                            [function]
  rule contains(A, A IL ) => true
  rule contains(A, B IL => IL)    requires A =/=Int B
  rule contains(_, .IntList) => false

  syntax IntList ::= intersection( IntList, IntList )                 [function, klabel(intersection)]
                   | intersection( IntList, IntList, IntList /*result*/) [function, klabel(intersection3)]
  rule intersection(L1, L2) => intersection(L1, L2, .IntList)
  rule intersection(A L1 => L1, L2, _)
    requires notBool contains(A, L2)
  rule intersection(A L1 => L1, L2, REZ => REZ +append A)
    requires contains(A, L2)
  rule intersection(.IntList, _, REZ) => REZ

  //returns the list with the first occurrence of the 2nd argument removed. Used in sorting.
  syntax IntList ::= listExcept( IntList , Int )                      [function, klabel(listExcept)]
                   | listExcept( IntList , Int , IntList /*result*/ ) [function, klabel(listExcept3)]
  rule listExcept(IL, EXCEPT) => listExcept(IL, EXCEPT, .IntList)
  rule listExcept( (I:Int IL) => IL, EXCEPT, REZ => REZ +append I )
    requires I =/=Int EXCEPT
  rule listExcept((EXCEPT IL) => .IntList /*terminate*/, EXCEPT, REZ => REZ +IntList IL /*dump the rest of the list without EXCEPT*/)
  rule listExcept(.IntList, _, REZ) => REZ

  syntax Int ::= sumMapIntValues( Map )                               [function]
               | sumMapIntValues( Map, Int )                          [function]
  rule sumMapIntValues(MAP) => sumMapIntValues(MAP, 0)
  rule sumMapIntValues(MAP:Map (_ |-> VALUE:Int => .Map), S => S +Int VALUE)
  rule sumMapIntValues(.Map, S) => S

  syntax Int ::= getByte(Root, Int) [function]
  rule getByte(BYTES:String, I) => ordChar(substrString(BYTES, I, I +Int 1))

  //IntList concatenation
  syntax IntList ::= IntList "+IntList" IntList     [function]
  rule (I IL1) +IntList IL2 => I (IL1 +IntList IL2)
  rule .IntList  +IntList IL2 => IL2

  // +append class of functions - appending at the end of user-list
  //---------------------------------------------------------------
  syntax IntList ::= IntList "+append" Int                            [function]
  rule (EL1:Int LIST) +append EL2 => EL1 (LIST +append EL2)
  rule .IntList +append EL => EL .IntList

  syntax BytesList ::= BytesList "+append" Bytes                      [function]
  rule (EL1:Bytes LIST) +append EL2 => EL1 (LIST +append EL2)
  rule .BytesList +append EL => EL .BytesList

  syntax PendingAttestationList ::= PendingAttestationList "+append" PendingAttestation [function]
  rule (EL1:PendingAttestation LIST) +append EL2 => EL1 (LIST +append EL2)
  rule .PendingAttestationList +append EL => EL .PendingAttestationList

  syntax Eth1DataList ::= Eth1DataList "+append" Eth1Data             [function]
  rule (EL1:Eth1Data LIST) +append EL2 => EL1 (LIST +append EL2)
  rule .Eth1DataList +append EL => EL .Eth1DataList


  //IntList merging (no duplicates)
  //Note: if the input lists duplicate-free, the resulting list will also be duplicate-free
  syntax IntList ::= IntList "++IntList" IntList     [function]
  rule IL1 ++IntList I IL2 => #if contains(I, IL1)
                                #then (IL1 ++IntList IL2)
                                #else (IL1 +append I) ++IntList IL2
                              #fi
  rule IL  ++IntList .IntList => IL

  syntax Bytes ::= Bytes "+Bytes" Bytes                               [function]
  rule B1 +Bytes B2 => B1 +String B2

  syntax Bytes ::= Bytes "*Bytes" Int                                 [function]
  rule B *Bytes I => (B *Bytes (I -Int 1)) +Bytes B
    requires I >Int 0
  rule B *Bytes 0 => ""

  //Dynamic length of a ValueList.
  syntax Int ::= len( ValueList )                                     [function]

  rule len(_ LIST:IntList) => 1 +Int len(LIST)
  rule len(.IntList) => 0
  rule len(_ LIST:BitList) => 1 +Int len(LIST)
  rule len(.BitList) => 0
  rule len(_ LIST:BytesList) => 1 +Int len(LIST)
  rule len(.BytesList) => 0

  rule len(_ LIST:ProposerSlashingList) => 1 +Int len(LIST)
  rule len(.ProposerSlashingList) => 0
  rule len(_ LIST:AttesterSlashingList) => 1 +Int len(LIST)
  rule len(.AttesterSlashingList) => 0
  rule len(_ LIST:AttestationList) => 1 +Int len(LIST)
  rule len(.AttestationList) => 0
  rule len(_ LIST:DepositList) => 1 +Int len(LIST)
  rule len(.DepositList) => 0
  rule len(_ LIST:DepositDataList) => 1 +Int len(LIST)
  rule len(.DepositDataList) => 0
  rule len(_ LIST:SignedVoluntaryExitList) => 1 +Int len(LIST)
  rule len(.SignedVoluntaryExitList) => 0
  rule len(_ LIST:ValidatorList) => 1 +Int len(LIST)
  rule len(.ValidatorList) => 0
  rule len(_ LIST:Eth1DataList) => 1 +Int len(LIST)
  rule len(.Eth1DataList) => 0
  rule len(_ LIST:PendingAttestationList) => 1 +Int len(LIST)
  rule len(.PendingAttestationList) => 0

  //Converts K-Map representation of a python List/Vector to a K-ValueList. Only implemented for used types.
  syntax ValueList ::= mapToList ( map: Map, index: Int, emptyList: ValueList ) [function]

  rule mapToList((INDEX |-> ELEM:ProposerSlashing) MAP, INDEX, EMPTY)
       => ELEM {mapToList(MAP, INDEX +Int 1, EMPTY)}:>ProposerSlashingList
  rule mapToList((INDEX |-> ELEM:Validator) MAP, INDEX, EMPTY)
       => ELEM {mapToList(MAP, INDEX +Int 1, EMPTY)}:>ValidatorList
  rule mapToList((INDEX |-> ELEM:Bytes) MAP, INDEX, EMPTY)
       => ELEM {mapToList(MAP, INDEX +Int 1, EMPTY)}:>BytesList
  rule mapToList((INDEX |-> ELEM:Int) MAP, INDEX, EMPTY)
       => ELEM {mapToList(MAP, INDEX +Int 1, EMPTY)}:>IntList

  rule mapToList(.Map, _, EMPTY) => EMPTY

  syntax BitList ::= removeLast(BitList)                              [function]
  rule removeLast(B1 B2 BL) => B1 removeLast(B2 BL)
  rule removeLast(B1 .BitList) => .BitList
  rule removeLast(.BitList) => .BitList

  syntax BitList ::= setBitAt(bitlist: BitList, index: Int, newBit: Bool) [function]
  rule setBitAt(I BL, INDEX, I') => I setBitAt(BL, INDEX -Int 1, I')
    requires INDEX >Int 0
  rule setBitAt(I BL, 0, I') => I' BL

  syntax BytesList ::= setBytesAt(BytesList, Int, Bytes)              [function]
  rule setBytesAt(RM RMS, INDEX, RM') => RM setBytesAt(RMS, INDEX -Int 1, RM')
    requires INDEX >Int 0
  rule setBytesAt(RM RMS, 0, RM') => RM' RMS

  syntax BitList ::= slice(BitList, Int, Int) [function]
  rule slice(BL:BitList, BEGIN, END) => dropTail(drop(BL, BEGIN), END -Int BEGIN)
    requires BEGIN >=Int 0 andBool END >=Int 0

  syntax BitList ::= drop(BitList, Int) [function]
  rule drop(I BL:BitList, BEGIN) => drop(BL, BEGIN -Int 1)
    requires BEGIN >Int 0
  rule drop(BL:BitList, BEGIN) => BL
    requires BEGIN <=Int 0

  syntax BitList ::= dropTail(BitList, Int) [function]
  rule dropTail(I BL:BitList, END) => I dropTail(BL, END -Int 1)
    requires END >Int 0
  rule dropTail(BL:BitList, END) => .BitList
    requires END <=Int 0

  syntax DepositDataList ::= slice(DepositDataList, Int, Int) [function]
  rule slice(BL:DepositDataList, BEGIN, END) => keepFirst(drop(BL, BEGIN), END -Int BEGIN)
    requires BEGIN >=Int 0 andBool END >=Int 0

  syntax DepositDataList ::= drop(DepositDataList, Int) [function]
  rule drop(I BL:DepositDataList, BEGIN) => drop(BL, BEGIN -Int 1)
    requires BEGIN >Int 0
  rule drop(BL:DepositDataList, BEGIN) => BL
    requires BEGIN <=Int 0

  syntax DepositDataList ::= keepFirst(DepositDataList, Int) [function]
  rule keepFirst(I BL:DepositDataList, N) => I keepFirst(BL, N -Int 1)
    requires N >Int 0
  rule keepFirst(BL:DepositDataList, N) => .DepositDataList
    requires N <=Int 0
  rule keepFirst(.DepositDataList, _) => .DepositDataList

  syntax Bool ::= allOnes(BitList) [function]
  rule allOnes(true BL) => allOnes(BL)
  rule allOnes(false BL) => false
  rule allOnes(.BitList) => true

  syntax Int ::= IntList "[" Int "]"                                  [function]
  rule (J:Int JL:IntList)[I] => JL[I -Int 1]
    requires I >Int 0
  rule (J:Int JL:IntList)[0] => J

  syntax Bytes ::= BytesList "[" Int "]"                              [function]
  rule (H:Bytes HL:BytesList)[I] => HL[I -Int 1]
    requires I >Int 0
  rule (H:Bytes HL:BytesList)[0] => H
  //Vector types might have less elements then their static size in the tests.
  //We must consider missing elements present and initialized with default value.
  rule (.BytesList)[I] => {defaultBytes32()}:>String //NOTEH will not work for Bytes of length != 32.

  syntax Map ::= initMapOfSize(Int) [function]
  rule initMapOfSize(I) => (I -Int 1 |-> 0) initMapOfSize(I -Int 1)
    requires I >Int 0
  rule initMapOfSize(0) => .Map

  //Fill in a vector of n instances of elem.
  syntax BytesList ::= fillInVector(elem: Bytes, n: Int)              [function]
  rule fillInVector(ELEM, N) => ELEM fillInVector(ELEM, N -Int 1)
    requires N >Int 0
  rule fillInVector(_, 0) => .BytesList

  syntax Map ::= fillInMap(elem: Value, n: Int)                       [function]
               | fillInMap(elem: Value, n: Int, i: Int)               [function]
  rule fillInMap(ELEM, N) => fillInMap(ELEM, N, 0)
  rule fillInMap(ELEM, N, I) => (I |-> ELEM) fillInMap(ELEM, N, I +Int 1)
    requires I <Int N
  rule fillInMap(ELEM, N, N) => .Map

endmodule
