#!/usr/bin/env python3

import sys

import pyk

from pyk.kast      import combineDicts, appliedLabelStr, constLabel, underbarUnparsing, K_symbols, KApply, KVariable, KToken
from pyk.kastManip import substitute, prettyPrintKast

BEACON_CHAIN_symbols = { }

BEACON_CHAIN_appliedLabels = [ "#Fork"
                             , "#Validator"
                             , "#Crosslink"
                             , "#BeaconBlockHeader"
                             , "#Eth1Data"
                             , "#AttestationData"
                             , "#PendingAttestation"
                             ]

for appliedLabel in BEACON_CHAIN_appliedLabels:
    BEACON_CHAIN_symbols[appliedLabel] = appliedLabelStr(appliedLabel)

BEACON_CHAIN_lists = [ "PendingAttestation"
                     , "Bytes32"
                     , "Uint64"
                     , "Eth1Data"
                     , "Crosslink"
                     ]

for list_sort in BEACON_CHAIN_lists:
    BEACON_CHAIN_symbols["." + list_sort + "List"] = constLabel("")
    BEACON_CHAIN_symbols[      list_sort + "List"] = underbarUnparsing("__")

ALL_symbols = combineDicts(K_symbols, BEACON_CHAIN_symbols)

# Read in the symbolic configuration
# configuration = readKastTerm(sys.argv[1])

symbolic_configuration = KApply ( '<beacon-chain>' , [ KApply ( '<k>', [ KVariable('K_CELL') ] )
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

init_cells = { 'K_CELL'                             : KToken('.Pgm', 'Pgm')
             , 'GENESIS_TIME_CELL'                  : KToken('0', 'Int')
             , 'SLOT_CELL'                          : KToken('0', 'Int')
             , 'FORK_CELL'                          : KToken('.Fork', 'Fork')
             , 'LATEST_BLOCK_HEADER_CELL'           : KToken('.BlockHeader', 'BlockHeader')
             , 'BLOCK_ROOTS_CELL'                   : KToken('.Map', 'Map')
             , 'STATE_ROOTS_CELL'                   : KToken('.Map', 'Map')
             , 'HISTORICAL_ROOTS_CELL'              : KToken('', 'HashList')
             , 'ETH1_DATA_CELL'                     : KToken('.Eth1Data', 'Eth1Data')
             , 'ETH1_DATA_VOTES_CELL'               : KToken('', 'Eth1DataList')
             , 'ETH1_DEPOSIT_INDEX_CELL'            : KToken('0', 'Int')
             , 'VALIDATORS_CELL'                    : KToken('.Map', 'Map')
             , 'BALANCES_CELL'                      : KToken('.Map', 'Map')
             , 'START_SHARD_CELL'                   : KToken('0', 'Int')
             , 'RANDAO_MIXES_CELL'                  : KToken('', 'HashList')
             , 'ACTIVE_INDEX_ROOTS_CELL'            : KToken('', 'HashList')
             , 'COMPACT_COMMITTEES_ROOTS_CELL'      : KToken('', 'HashList')
             , 'SLASHINGS_CELL'                     : KToken('.Map', 'Map')
             , 'PREVIOUS_EPOCH_ATTESTATION_CELL'    : KToken('', 'PendingAttestationList')
             , 'CURRENT_EPOCH_ATTESTATIONS_CELL'    : KToken('', 'PendingAttestationList')
             , 'PREVIOUS_CROSSLINKS_CELL'           : KToken('.Map', 'Map')
             , 'CURRENT_CROSSLINKS_CELL'            : KToken('.Map', 'Map')
             , 'JUSTIFICATION_BITS_CELL'            : KToken('', 'BitList')
             , 'PREVIOUS_JUSTIFIED_CHECKPOINT_CELL' : KToken('.Checkpoint', 'Checkpoint')
             , 'CURRENT_JUSTIFIED_CHECKPOINT_CELL'  : KToken('.Checkpoint', 'Checkpoint')
             , 'FINALIZED_CHECKPOINT_CELL'          : KToken('.Checkpoint', 'Checkpoint')
             , 'BLOCKSLOT_CELL'                     : KToken('-1', 'Int')
             , 'PARENT_ROOT_CELL'                   : KToken('-1', 'Int')
             , 'STATE_ROOT_CELL'                    : KToken('-1', 'Int')
             , 'RANDAO_REVEAL_CELL'                 : KToken('-1', 'Int')
             , 'BLOCK-ETH1_DATA_CELL'               : KToken('.Eth1Data', 'Eth1Data')
             , 'GRAFFITI_CELL'                      : KToken('-1', 'Int')
             , 'PROPOSER_SLASHINGS_CELL'            : KToken('.ProposerSlashingCellMap', 'ProposerSlashingCellMap')
             , 'ATTESTER_SLASHINGS_CELL'            : KToken('', 'AttesterSlashingList')
             , 'ATTESTATIONS_CELL'                  : KToken('', 'AttestationList')
             , 'DEPOSITS_CELL'                      : KToken('', 'DepositList')
             , 'VOLUNTARY_EXITS_CELL'               : KToken('', 'VoluntaryExitList')
             , 'TRANSFERS_CELL'                     : KToken('', 'TransferList')
             , 'SIGNATURE_CELL'                     : KToken('-1', 'Int')
             }

if __name__ == "__main__":
    instantiated_configuration = substitute(symbolic_configuration, init_cells)
    print(prettyPrintKast(instantiated_configuration, ALL_symbols))
    sys.exit(0)
