#!/usr/bin/env python3

import sys

# From K's pyk-library
from util import *
from kast import *
from pyk  import *

ALL_symbols = K_symbols

# Read in the symbolic configuration
# configuration = readKastTerm(sys.argv[1])

symbolic_configuration = KApply ( '<generatedTop>' , [ KApply ( '<k>', [ KVariable('K_CELL') ] )
                                                     , KApply ( '<state>' , [ KApply ( '<slot>'                        , [ KVariable('SLOT_CELL')                       ] )
                                                                            , KApply ( '<genesis-time>'                , [ KVariable('GENESIS_TIME_CELL')               ] )
                                                                            , KApply ( '<fork>'                        , [ KVariable('FORK_CELL')                       ] )
                                                                            , KApply ( '<validator-registry>'          , [ KVariable('VALIDATOR_REGISTRY_CELL')         ] )
                                                                            , KApply ( '<balances>'                    , [ KVariable('BALANCES_CELL')                   ] )
                                                                            , KApply ( '<latest-randao-mixes>'         , [ KVariable('LATEST_RANDAO_MIXES_CELL')        ] )
                                                                            , KApply ( '<latest-start-shard>'          , [ KVariable('LATEST_START_SHARD_CELL')         ] )
                                                                            , KApply ( '<previous-epoch-attestations>' , [ KVariable('PREVIOUS_EPOCH_ATTESTATION_CELL') ] )
                                                                            , KApply ( '<current-epoch-attestations>'  , [ KVariable('CURRENT_EPOCH_ATTESTATIONS_CELL') ] )
                                                                            , KApply ( '<previous-justified-epoch>'    , [ KVariable('PREVIOUS_JUSTIFIED_EPOCH_CELL')   ] )
                                                                            , KApply ( '<current-justified-epoch>'     , [ KVariable('CURRENT_JUSTIFIED_EPOCH_CELL')    ] )
                                                                            , KApply ( '<previous-justified-root>'     , [ KVariable('PREVIOUS_JUSTIFIED_ROOT_CELL')    ] )
                                                                            , KApply ( '<current-justified-root>'      , [ KVariable('CURRENT_JUSTIFIED_ROOT_CELL')     ] )
                                                                            , KApply ( '<justification-bitfield>'      , [ KVariable('JUSTIFICATION_BITFIELD_CELL')     ] )
                                                                            , KApply ( '<finalized-epoch>'             , [ KVariable('FINALIZED_EPOCH_CELL')            ] )
                                                                            , KApply ( '<finalized-root>'              , [ KVariable('FINALIZED_ROOT_CELL')             ] )
                                                                            , KApply ( '<current-crosslinks>'          , [ KVariable('CURRENT_CROSSLINKS_CELL')         ] )
                                                                            , KApply ( '<previous-crosslinks>'         , [ KVariable('PREVIOUS_CROSSLINKS_CELL')        ] )
                                                                            , KApply ( '<latest-block-roots>'          , [ KVariable('LATEST_BLOCK_ROOTS_CELL')         ] )
                                                                            , KApply ( '<latest-state-roots>'          , [ KVariable('LATEST_STATE_ROOTS_CELL')         ] )
                                                                            , KApply ( '<latest-active-index-roots>'   , [ KVariable('LATEST_ACTIVE_INDEX_ROOTS_CELL')  ] )
                                                                            , KApply ( '<latest-slashed-balances>'     , [ KVariable('LATEST_SLASHED_BALANCE_CELL')     ] )
                                                                            , KApply ( '<latest-block-header>'         , [ KVariable('LATEST_BLOCK_HEADER_CELL')        ] )
                                                                            , KApply ( '<historical-roots>'            , [ KVariable('HISTORICAL_ROOTS_CELL')           ] )
                                                                            , KApply ( '<latest-eth1-data>'            , [ KVariable('LATEST_ETH1_CELL')                ] )
                                                                            , KApply ( '<eth1-data-votes>'             , [ KVariable('ETH1_DATA_VOTES_CELL')            ] )
                                                                            , KApply ( '<deposit-index>'               , [ KVariable('DEPOSIT_INDEX_CELL')              ] )
                                                                            ]
                                                              )
                                                     , KApply ( '<block>' , [ KApply ( '<blockSlot>'   , [ KVariable('BLOCKSLOT_CELL')   ] )
                                                                            , KApply ( '<parent-root>' , [ KVariable('PARENT_ROOT_CELL') ] )
                                                                            , KApply ( '<state-root>'  , [ KVariable('STATE_ROOT_CELL')  ] )
                                                                            , KApply ( '<body>' , [ KApply ( '<randao-reveal>'      , [ KVariable('RANDAO_REVEAL_CELL')      ] )
                                                                                                  , KApply ( '<eth1-data>'          , [ KVariable('ETH1_DATA_CELL')          ] )
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

print(prettyPrintKast(symbolic_configuration, ALL_symbols))
