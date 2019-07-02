#!/usr/bin/env python3

import sys
import yaml

from functools import reduce

from buildConfig import *

intToken    = lambda x: KToken(str(x), 'Int')
boolToken   = lambda x: KToken(str(x).lower(), 'Bool')
stringToken = lambda x: KToken('"' + str(x) + '"', 'String')

hexIntToken = lambda x: intToken(int(x, 16))

unimplemented = lambda input: KToken("UNIMPLEMENTED << " + str(input) + " >>", "K")

foldr = lambda func, init: lambda xs: reduce(lambda x, y: func(y, x), xs[::-1], init)

def assocWithUnitAST(joinKLabel, emptyKLabel, converter = lambda x: x):
    emptyElem = KApply(emptyKLabel, [])
    _join = lambda head, tail: KApply(joinKLabel, [converter(head), tail])
    return foldr(_join, KApply(emptyKLabel, []))

def indexedMapOf(mapElement):
    def _indexedMapOf(inputList):
        mapElements = [ KApply("_|->_", [intToken(k), mapElement(v)]) for (k,v) in enumerate(inputList) ]
        return assocWithUnitAST("_Map_", ".Map")(mapElements)
    return _indexedMapOf

def listOf(sort, converter = lambda x: x):
    listSort = sort + "List"
    listUnit = "." + listSort
    return assocWithUnitAST(listSort, listUnit, converter = converter)

def labelWithKeyPairs(label, keyConverters):
    def _labelWithKeyPairs(input):
        args = [ converter(input[key]) for (key, converter) in keyConverters ]
        return KApply(label, args)
    return _labelWithKeyPairs


forkTerm = labelWithKeyPairs("#Fork" , [ ('previous_version' , hexIntToken)
                                       , ('current_version'  , hexIntToken)
                                       , ('epoch'            , intToken)
                                       ]
                            )

validatorTerm = labelWithKeyPairs("#Validator" , [ ('pubkey'                       , hexIntToken)
                                                 , ('withdrawal_credentials'       , hexIntToken)
                                                 , ('activation_eligibility_epoch' , intToken)
                                                 , ('activation_epoch'             , intToken)
                                                 , ('exit_epoch'                   , intToken)
                                                 , ('withdrawable_epoch'           , intToken)
                                                 , ('slashed'                      , boolToken)
                                                 , ('effective_balance'            , intToken)
                                                 ]
                                 )

crosslinkTerm = labelWithKeyPairs("#Crosslink" , [ ('shard'       , intToken)
                                                 , ('start_epoch' , intToken)
                                                 , ('end_epoch'   , intToken)
                                                 , ('parent_root' , hexIntToken)
                                                 , ('data_root'   , hexIntToken)
                                                 ]
                                 )

blockheaderTerm = labelWithKeyPairs("#BeaconBlockHeader" , [ ('slot'        , intToken)
                                                           , ('parent_root' , hexIntToken)
                                                           , ('state_root'  , hexIntToken)
                                                           , ('body_root'   , hexIntToken)
                                                           , ('signature'   , hexIntToken)
                                                           ]
                                   )

eth1dataTerm = labelWithKeyPairs("#Eth1Data" , [ ('deposit_root'  , hexIntToken)
                                               , ('deposit_count' , intToken)
                                               , ('block_hash'    , hexIntToken)
                                               ]
                                )

attestationDataTerm = labelWithKeyPairs("#AttestationData" , [ ('beacon_block_root' , hexIntToken)
                                                             , ('source_epoch'      , intToken)
                                                             , ('source_root'       , hexIntToken)
                                                             , ('target_epoch'      , intToken)
                                                             , ('target_root'       , hexIntToken)
                                                             , ('crosslink'         , crosslinkTerm)
                                                             ]
                                       )

pendingAttestationTerm = labelWithKeyPairs("#PendingAttestation" , [ ('aggregation_bitfield' , hexIntToken)
                                                                   , ('data'                 , attestationDataTerm)
                                                                   , ('inclusion_delay'      , intToken)
                                                                   , ('proposer_index'       , intToken)
                                                                   ]
                                          )

pre_keys = { "slot"                        : ('SLOT_CELL'                       , intToken)
           , "genesis_time"                : ('GENESIS_TIME_CELL'               , intToken)
           , "fork"                        : ('FORK_CELL'                       , forkTerm)
           , "validator_registry"          : ('VALIDATOR_REGISTRY_CELL'         , indexedMapOf(validatorTerm))
           , "balances"                    : ('BALANCES_CELL'                   , indexedMapOf(intToken))
           , "latest_randao_mixes"         : ('LATEST_RANDAO_MIXES_CELL'        , listOf("Bytes32", converter = hexIntToken))
           , "latest_start_shard"          : ('LATEST_START_SHARD_CELL'         , intToken)
           , "previous_epoch_attestations" : ('PREVIOUS_EPOCH_ATTESTATION_CELL' , listOf("PendingAttestation", converter = pendingAttestationTerm))
           , "current_epoch_attestations"  : ('CURRENT_EPOCH_ATTESTATIONS_CELL' , listOf("PendingAttestation", converter = pendingAttestationTerm))
           , "previous_justified_epoch"    : ('PREVIOUS_JUSTIFIED_EPOCH_CELL'   , intToken)
           , "current_justified_epoch"     : ('CURRENT_JUSTIFIED_EPOCH_CELL'    , intToken)
           , "previous_justified_root"     : ('PREVIOUS_JUSTIFIED_ROOT_CELL'    , hexIntToken)
           , "current_justified_root"      : ('CURRENT_JUSTIFIED_ROOT_CELL'     , hexIntToken)
           , "justification_bitfield"      : ('JUSTIFICATION_BITFIELD_CELL'     , intToken)
           , "finalized_epoch"             : ('FINALIZED_EPOCH_CELL'            , intToken)
           , "finalized_root"              : ('FINALIZED_ROOT_CELL'             , hexIntToken)
           , "current_crosslinks"          : ('CURRENT_CROSSLINKS_CELL'         , listOf("Crosslink", converter = crosslinkTerm))
           , "previous_crosslinks"         : ('PREVIOUS_CROSSLINKS_CELL'        , listOf("Crosslink", converter = crosslinkTerm))
           , "latest_block_roots"          : ('LATEST_BLOCK_ROOTS_CELL'         , listOf("Bytes32", converter = hexIntToken))
           , "latest_state_roots"          : ('LATEST_STATE_ROOTS_CELL'         , listOf("Bytes32", converter = hexIntToken))
           , "latest_active_index_roots"   : ('LATEST_ACTIVE_INDEX_ROOTS_CELL'  , listOf("Bytes32", converter = hexIntToken))
           , "latest_slashed_balances"     : ('LATEST_SLASHED_BALANCE_CELL'     , listOf("Uint64", converter = intToken))
           , "latest_block_header"         : ('LATEST_BLOCK_HEADER_CELL'        , blockheaderTerm)
           , "historical_roots"            : ('HISTORICAL_ROOTS_CELL'           , listOf("Bytes32", converter = intToken))
           , "latest_eth1_data"            : ('LATEST_ETH1_DATA_CELL'           , eth1dataTerm)
           , "eth1_data_votes"             : ('ETH1_DATA_VOTES_CELL'            , listOf("Eth1Data", converter = eth1dataTerm))
           , "deposit_index"               : ('DEPOSIT_INDEX_CELL'              , intToken)
           }

def emptyKLabelsToEmptyTokens(k):
    _emptyKLabelsToEmptyTokens = [ (KApply(".Map", []), KToken("", "Map"))
                                 ]
    newK = k
    for rule in _emptyKLabelsToEmptyTokens:
        newK = rewriteAnywhereWith(rule, newK)
    return newK

if __name__ == "__main__":
    test_file = sys.argv[1]

    with open(test_file, "r") as yaml_file:
        yaml_test = yaml.load(yaml_file, Loader = yaml.FullLoader)

    keytable = init_cells

    # for test_case in yaml_test['test_cases']:
    test_case = yaml_test['test_cases'][0]

    print()
    print()
    print()
    print("test description: " + test_case['description'])

    for pre_key in test_case['pre'].keys():
        test_pre = test_case['pre'][pre_key]
        if pre_key in pre_keys:
            (cell_var, converter) = pre_keys[pre_key]
            if cell_var in keytable:
                print(pre_key)
                keytable[cell_var] = converter(test_pre)
            else:
                print("unimplemented pre-key: " + str(pre_key) + " -> " + str(test_pre))
        elif len(str(test_pre)) < 3:
            print("unused pre-key: " + pre_key)

    if test_case['post'] is None:
        print("No post condition!")
    else:
        print("post keys: " + str(test_case['post'].keys()))

    init_config = emptyKLabelsToEmptyTokens(substitute(symbolic_configuration, keytable))
    print(prettyPrintKast(init_config, ALL_symbols))
