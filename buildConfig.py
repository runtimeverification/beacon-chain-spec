#!/usr/bin/env python3

import json
import sys
import tempfile

from functools import reduce

import pyk

from pyk.kast      import combineDicts, appliedLabelStr, constLabel, underbarUnparsing, K_symbols, KApply, KConstant, KSequence, KVariable, KToken
from pyk.kastManip import substitute, prettyPrintKast

def printerr(msg):
    sys.stderr.write(msg + '\n')

intToken    = lambda x: KToken(str(x), 'Int')
boolToken   = lambda x: KToken(str(x).lower(), 'Bool')
stringToken = lambda x: KToken(''' + str(x) + ''', 'String')

hexIntToken = lambda x: intToken(int(x, 16))

unimplemented = lambda input: KToken('UNIMPLEMENTED << ' + str(input) + ' >>', 'K')

foldr = lambda func, init: lambda xs: reduce(lambda x, y: func(y, x), xs[::-1], init)

def assocSort(elemSort):
    return '_TYPES__' + elemSort + '_' + elemSort + 'List'

def assocJoin(elemSort):
    return '__' + assocSort(elemSort)

def assocUnit(elemSort):
    return '.List{"' + assocJoin(elemSort) + '"}_' + elemSort + 'List'

def assocWithUnitAST(joinKLabel, emptyKLabel, converter = lambda x: x):
    emptyElem = KApply(emptyKLabel, [])
    _join = lambda head, tail: KApply(joinKLabel, [converter(head), tail])
    return foldr(_join, KApply(emptyKLabel, []))

def indexedMapOf(converter = lambda x: x):
    def _indexedMapOf(inputList):
        mapElements = [ KApply('_|->_', [intToken(k), converter(v)]) for (k,v) in enumerate(inputList) ]
        return assocWithUnitAST('_Map_', '.Map')(mapElements)
    return _indexedMapOf

def listOf(sort, converter = lambda x: x):
    lJoin = '__' + assocSort(sort)
    lUnit = assocUnit(sort)
    return assocWithUnitAST(lJoin, lUnit, converter = converter)

def labelWithKeyPairs(label, keyConverters):
    def _labelWithKeyPairs(input):
        args = [ converter(input[key]) for (key, converter) in keyConverters ]
        return KApply(label, args)
    return _labelWithKeyPairs

def kast(inputFile, *kastArgs):
    return pyk.kast('.build/defn/llvm', inputFile, kastArgs = list(kastArgs), kRelease = 'deps/k/k-distribution/target/release/k')

def krun(inputFile, *krunArgs):
    return pyk.krun('.build/defn/llvm', inputFile, krunArgs = list(krunArgs), kRelease = 'deps/k/k-distribution/target/release/k')

BEACON_CHAIN_symbols = { '.ProposerSlashingCellMap' : constLabel('.ProposerSlashingCellMap') }

BEACON_CHAIN_constLabels = [ '.Pgm'
                           , '.Eth1Data'
                           ]

for cLabel in BEACON_CHAIN_constLabels:
    BEACON_CHAIN_symbols[cLabel + '_BEACON-CHAIN_'] = constLabel(cLabel)

BEACON_CHAIN_appliedLabels = [ '#Fork'
                             , '#Validator'
                             , '#Crosslink'
                             , '#BeaconBlockHeader'
                             , '#Eth1Data'
                             , '#AttestationData'
                             , '#PendingAttestation'
                             ]

for appliedLabel in BEACON_CHAIN_appliedLabels:
    BEACON_CHAIN_symbols[appliedLabel] = appliedLabelStr(appliedLabel)

BEACON_CHAIN_lists = [ 'PendingAttestation'
                     , 'AttesterSlashing'
                     , 'Attestation'
                     , 'Deposit'
                     , 'VoluntaryExit'
                     , 'Transfer'
                     , 'Bytes32'
                     , 'Uint64'
                     , 'Eth1Data'
                     , 'Crosslink'
                     , 'Hash'
                     ]

for list_sort in BEACON_CHAIN_lists:
    BEACON_CHAIN_symbols[assocUnit(list_sort)] = constLabel('.' + list_sort + 'List')
    BEACON_CHAIN_symbols[assocJoin(list_sort)] = underbarUnparsing('__')

ALL_symbols = combineDicts(K_symbols, BEACON_CHAIN_symbols)

# Read in the symbolic configuration
# configuration = readKastTerm(sys.argv[1])

symbolic_configuration = KApply ( '<generatedTop>' , [ KApply ( '<beacon-chain>' , [ KApply ( '<k>', [ KVariable('K_CELL') ] )
                                                                                   , KApply ( '<state>' , [ KApply ( '<genesis-time>'                  , [ KVariable('GENESIS_TIME_CELL')                  ] )
                                                                                                          , KApply ( '<slot>'                          , [ KVariable('SLOT_CELL')                          ] )
                                                                                                          , KApply ( '<fork>'                          , [ KVariable('FORK_CELL')                          ] )
                                                                                                          , KApply ( '<latest-block-header>'           , [ KVariable('LATEST_BLOCK_HEADER_CELL')           ] )
                                                                                                          , KApply ( '<block-roots>'                   , [ KVariable('BLOCK_ROOTS_CELL')                   ] )
                                                                                                          , KApply ( '<state-roots>'                   , [ KVariable('STATE_ROOTS_CELL')                   ] )
                                                                                                          , KApply ( '<historical-roots>'              , [ KVariable('HISTORICAL_ROOTS_CELL')              ] )
                                                                                                          , KApply ( '<eth1-data>'                     , [ KVariable('ETH1_DATA_CELL')                     ] )
                                                                                                          , KApply ( '<eth1-data-votes>'               , [ KVariable('ETH1_DATA_VOTES_CELL')               ] )
                                                                                                          , KApply ( '<eth1-deposit-index>'            , [ KVariable('ETH1_DEPOSIT_INDEX_CELL')            ] )
                                                                                                          , KApply ( '<validators>'                    , [ KVariable('VALIDATORS_CELL')                    ] )
                                                                                                          , KApply ( '<balances>'                      , [ KVariable('BALANCES_CELL')                      ] )
                                                                                                          , KApply ( '<start-shard>'                   , [ KVariable('START_SHARD_CELL')                   ] )
                                                                                                          , KApply ( '<randao-mixes>'                  , [ KVariable('RANDAO_MIXES_CELL')                  ] )
                                                                                                          , KApply ( '<active-index-roots>'            , [ KVariable('ACTIVE_INDEX_ROOTS_CELL')            ] )
                                                                                                          , KApply ( '<compact-committees-roots>'      , [ KVariable('COMPACT_COMMITTEES_ROOTS_CELL')      ] )
                                                                                                          , KApply ( '<slashings>'                     , [ KVariable('SLASHINGS_CELL')                     ] )
                                                                                                          , KApply ( '<previous-epoch-attestations>'   , [ KVariable('PREVIOUS_EPOCH_ATTESTATION_CELL')    ] )
                                                                                                          , KApply ( '<current-epoch-attestations>'    , [ KVariable('CURRENT_EPOCH_ATTESTATIONS_CELL')    ] )
                                                                                                          , KApply ( '<previous-crosslinks>'           , [ KVariable('PREVIOUS_CROSSLINKS_CELL')           ] )
                                                                                                          , KApply ( '<current-crosslinks>'            , [ KVariable('CURRENT_CROSSLINKS_CELL')            ] )
                                                                                                          , KApply ( '<justification-bits>'            , [ KVariable('JUSTIFICATION_BITS_CELL')            ] )
                                                                                                          , KApply ( '<previous-justified-checkpoint>' , [ KVariable('PREVIOUS_JUSTIFIED_CHECKPOINT_CELL') ] )
                                                                                                          , KApply ( '<current-justified-checkpoint>'  , [ KVariable('CURRENT_JUSTIFIED_CHECKPOINT_CELL')  ] )
                                                                                                          , KApply ( '<finalized-checkpoint>'          , [ KVariable('FINALIZED_CHECKPOINT_CELL')          ] )
                                                                                                        ]
                                                                                          )
                                                                                 , KApply ( '<block>' , [ KApply ( '<blockSlot>'   , [ KVariable('BLOCKSLOT_CELL')   ] )
                                                                                                        , KApply ( '<parent-root>' , [ KVariable('PARENT_ROOT_CELL') ] )
                                                                                                        , KApply ( '<state-root>'  , [ KVariable('STATE_ROOT_CELL')  ] )
                                                                                                        , KApply ( '<body>' , [ KApply ( '<randao-reveal>'      , [ KVariable('RANDAO_REVEAL_CELL')      ] )
                                                                                                                              , KApply ( '<block-eth1-data>'    , [ KVariable('BLOCK-ETH1_DATA_CELL')    ] )
                                                                                                                              , KApply ( '<graffiti>'           , [ KVariable('GRAFFITI_CELL')           ] )
                                                                                                                              , KApply ( '<proposer-slashings>' , [ KVariable('PROPOSER_SLASHINGS_CELL') ] )
                                                                                                                              , KApply ( '<attester-slashings>' , [ KVariable('ATTESTER_SLASHINGS_CELL') ] )
                                                                                                                              , KApply ( '<attestations>'       , [ KVariable('ATTESTATIONS_CELL')       ] )
                                                                                                                              , KApply ( '<deposits>'           , [ KVariable('DEPOSITS_CELL')           ] )
                                                                                                                              , KApply ( '<voluntary-exits>'    , [ KVariable('VOLUNTARY_EXITS_CELL')    ] )
                                                                                                                              , KApply ( '<transfers>'          , [ KVariable('TRANSFERS_CELL')          ] )
                                                                                                                              ]
                                                                                                                 )
                                                                                                         , KApply ( '<signature>', [ KVariable('SIGNATURE_CELL') ] )
                                                                                                         ]
                                                                                          )
                                                                                 ]
                                                              )
                                                     , KApply ( '<generatedCounter>' , [ KVariable('GENERATED_COUNTER_CELL') ] )
                                                     ]
                                )

init_cells = { 'K_CELL'                             : KSequence([KConstant('.Pgm_BEACON-CHAIN_')])
             , 'GENESIS_TIME_CELL'                  : KToken('0', 'Int')
             , 'SLOT_CELL'                          : KToken('0', 'Int')
             , 'FORK_CELL'                          : KConstant('.Fork_BEACON-CHAIN_')
             , 'LATEST_BLOCK_HEADER_CELL'           : KConstant('.BlockHeader_BEACON-CHAIN_')
             , 'BLOCK_ROOTS_CELL'                   : KConstant('.Map')
             , 'STATE_ROOTS_CELL'                   : KConstant('.Map')
             , 'HISTORICAL_ROOTS_CELL'              : listOf('Hash')([])
             , 'ETH1_DATA_CELL'                     : KConstant('.Eth1Data_BEACON-CHAIN_')
             , 'ETH1_DATA_VOTES_CELL'               : listOf('Eth1Data')([])
             , 'ETH1_DEPOSIT_INDEX_CELL'            : KToken('0', 'Int')
             , 'VALIDATORS_CELL'                    : KConstant('.Map')
             , 'BALANCES_CELL'                      : KConstant('.Map')
             , 'START_SHARD_CELL'                   : KToken('0', 'Int')
             , 'RANDAO_MIXES_CELL'                  : listOf('Hash')([])
             , 'ACTIVE_INDEX_ROOTS_CELL'            : listOf('Hash')([])
             , 'COMPACT_COMMITTEES_ROOTS_CELL'      : listOf('Hash')([])
             , 'SLASHINGS_CELL'                     : KConstant('.Map')
             , 'PREVIOUS_EPOCH_ATTESTATION_CELL'    : listOf('PendingAttestation')([])
             , 'CURRENT_EPOCH_ATTESTATIONS_CELL'    : listOf('PendingAttestation')([])
             , 'PREVIOUS_CROSSLINKS_CELL'           : KConstant('.Map')
             , 'CURRENT_CROSSLINKS_CELL'            : KConstant('.Map')
             , 'JUSTIFICATION_BITS_CELL'            : listOf('Bit')([])
             , 'PREVIOUS_JUSTIFIED_CHECKPOINT_CELL' : KConstant('.Checkpoint_BEACON-CHAIN_')
             , 'CURRENT_JUSTIFIED_CHECKPOINT_CELL'  : KConstant('.Checkpoint_BEACON-CHAIN_')
             , 'FINALIZED_CHECKPOINT_CELL'          : KConstant('.Checkpoint_BEACON-CHAIN_')
             , 'BLOCKSLOT_CELL'                     : KToken('-1', 'Int')
             , 'PARENT_ROOT_CELL'                   : KToken('-1', 'Int')
             , 'STATE_ROOT_CELL'                    : KToken('-1', 'Int')
             , 'RANDAO_REVEAL_CELL'                 : KToken('-1', 'Int')
             , 'BLOCK-ETH1_DATA_CELL'               : KConstant('.Eth1Data_BEACON-CHAIN_')
             , 'GRAFFITI_CELL'                      : KToken('-1', 'Int')
             , 'PROPOSER_SLASHINGS_CELL'            : KConstant('.ProposerSlashingCellMap')
             , 'ATTESTER_SLASHINGS_CELL'            : listOf('AttesterSlashing')([])
             , 'ATTESTATIONS_CELL'                  : listOf('Attestation')([])
             , 'DEPOSITS_CELL'                      : listOf('Deposit')([])
             , 'VOLUNTARY_EXITS_CELL'               : listOf('VoluntaryExit')([])
             , 'TRANSFERS_CELL'                     : listOf('Transfer')([])
             , 'SIGNATURE_CELL'                     : KToken('-1', 'Int')
             , 'GENERATED_COUNTER_CELL'             : KToken('0', 'Int')
             }

initial_configuration = substitute(symbolic_configuration, init_cells)

if __name__ == '__main__':
    kast_json = { 'format': 'KAST', 'version': 1, 'term': initial_configuration }
    with tempfile.NamedTemporaryFile(mode = 'w') as tempf:
        json.dump(kast_json, tempf)
        tempf.flush()
        (returnCode, _, _) = kast(tempf.name, '--input', 'json', '--output', 'pretty')
        if returnCode != 0:
            printerr('[FATAL] kast returned non-zero exit code reading/printing the initial configuration')
            sys.exit(returnCode)
