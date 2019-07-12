#!/usr/bin/env python3

import sys
import yaml

from functools import reduce

from buildConfig import *

def printerr(msg):
    sys.stderr.write(msg + "\n")

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
    listSort = "___BEACON-CHAIN__" + sort + "_" + sort + "List"
    listUnit = ".List{\"" + listSort + "\"}_" + sort + "List"
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

checkpointTerm = labelWithKeyPairs("#Checkpoint" , [ ('epoch' , intToken)
                                                   , ('root'  , hexIntToken)
                                                   ]
                                  )

validatorTerm = labelWithKeyPairs("#Validator" , [ ('pubkey'                       , hexIntToken)
                                                 , ('withdrawal_credentials'       , hexIntToken)
                                                 , ('effective_balance'            , intToken)
                                                 , ('slashed'                      , boolToken)
                                                 , ('activation_eligibility_epoch' , intToken)
                                                 , ('activation_epoch'             , intToken)
                                                 , ('exit_epoch'                   , intToken)
                                                 , ('withdrawable_epoch'           , intToken)
                                                 ]
                                 )

crosslinkTerm = labelWithKeyPairs("#Crosslink" , [ ('shard'       , intToken)
                                                 , ('parent_root' , hexIntToken)
                                                 , ('start_epoch' , intToken)
                                                 , ('end_epoch'   , intToken)
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
                                                             , ('source'            , checkpointTerm)
                                                             , ('target'            , checkpointTerm)
                                                             , ('crosslink'         , crosslinkTerm)
                                                             ]
                                       )

pendingAttestationTerm = labelWithKeyPairs("#PendingAttestation" , [ ('aggregation_bits'     , listOf("Bit", converter = intToken))
                                                                   , ('data'                 , attestationDataTerm)
                                                                   , ('inclusion_delay'      , intToken)
                                                                   , ('proposer_index'       , intToken)
                                                                   ]
                                          )

pre_keys = { "genesis_time"                  : ('GENESIS_TIME_CELL'               , intToken)
           , "slot"                          : ('SLOT_CELL'                       , intToken)
           , "fork"                          : ('FORK_CELL'                       , forkTerm)
           , "latest_block_header"           : ('LATEST_BLOCK_HEADER_CELL'        , blockheaderTerm)
           , "block_roots"                   : ('BLOCK_ROOTS_CELL'                , listOf("Bytes32", converter = hexIntToken))
           , "state_roots"                   : ('STATE_ROOTS_CELL'                , listOf("Bytes32", converter = hexIntToken))
           , "historical_roots"              : ('HISTORICAL_ROOTS_CELL'           , listOf("Bytes32", converter = intToken))
           , "eth1_data"                     : ('ETH1_DATA_CELL'                  , eth1dataTerm)
           , "eth1_data_votes"               : ('ETH1_DATA_VOTES_CELL'            , listOf("Eth1Data", converter = eth1dataTerm))
           , "eth1_deposit_index"            : ('ETH1_DEPOSIT_INDEX_CELL'         , intToken)
           , "validators"                    : ('VALIDATORS_CELL'                 , indexedMapOf(validatorTerm))
           , "balances"                      : ('BALANCES_CELL'                   , indexedMapOf(intToken))
           , "start_shard"                   : ('START_SHARD_CELL'                , intToken)
           , "randao_mixes"                  : ('RANDAO_MIXES_CELL'               , listOf("Bytes32", converter = hexIntToken))
           , "active_index_roots"            : ('ACTIVE_INDEX_ROOTS_CELL'         , listOf("Bytes32", converter = hexIntToken))
           , "compact_committees_roots"      : ('COMPACT_COMMITTEES_ROOTS'        , listOf("Bytes32", converter = hexIntToken))
           , "slashings"                     : ('SLASHINGS'                       , indexedMapOf(intToken))
           , "previous_epoch_attestations"   : ('PREVIOUS_EPOCH_ATTESTATION_CELL' , listOf("PendingAttestation", converter = pendingAttestationTerm))
           , "current_epoch_attestations"    : ('CURRENT_EPOCH_ATTESTATIONS_CELL' , listOf("PendingAttestation", converter = pendingAttestationTerm))
           , "previous_crosslinks"           : ('PREVIOUS_CROSSLINKS_CELL'        , listOf("Crosslink", converter = crosslinkTerm))
           , "current_crosslinks"            : ('CURRENT_CROSSLINKS_CELL'         , listOf("Crosslink", converter = crosslinkTerm))
           , "justification_bits"            : ('JUSTIFICATION_BITS'              , listOf("Uint64", converter = intToken))
           , "previous_justified_checkpoint" : ('PREVIOUS_JUSTIFIED_CHECKPOINT'   , checkpointTerm)
           , "current_justified_checkpoint"  : ('CURRENT_JUSTIFIED_CHECKPOINT'    , checkpointTerm)
           , "finalized_checkpoint"          : ('FINALIZED_CHECKPOINT'            , checkpointTerm)
           }

def emptyKLabelsToEmptyTokens(k):
    _emptyKLabelsToEmptyTokens = [ (KApply(".Map", []), KToken("", "Map"))
                                 ]
    newK = k
    for rule in _emptyKLabelsToEmptyTokens:
        newK = rewriteAnywhereWith(rule, newK)
    return newK

if __name__ == "__main__":
    test_file   = sys.argv[1]
    output_json = sys.argv[2]

    with open(test_file, "r") as yaml_file:
        yaml_test = yaml.load(yaml_file, Loader = yaml.FullLoader)

    keytable = init_cells

    # **TODO**: We need to run all the tests:
    # for test_case in yaml_test['test_cases']:
    test_case = yaml_test['test_cases'][0]

    printerr("test description: " + test_case['description'])

    for pre_key in test_case['pre'].keys():
        test_pre = test_case['pre'][pre_key]
        if pre_key in pre_keys:
            (cell_var, converter) = pre_keys[pre_key]
            if cell_var in keytable:
                keytable[cell_var] = converter(test_pre)
            else:
                printerr("unimplemented pre-key: " + str(pre_key) + " -> " + str(test_pre))
        elif len(str(test_pre)) < 3:
            printerr("unused pre-key: " + pre_key)

    if 'transfer' in test_case:
        printerr("Skipping transfer block!")

    if test_case['post'] is None:
        printerr("No post condition!")
    else:
        printerr("Skipping post block!")

    kast_json = { "format"  : "KAST"
                , "version" : 1.0
                , "term"    : substitute(symbolic_configuration, keytable)
                }
    with open(output_json, "w") as output_json_file:
        json.dump(kast_json, output_json_file)
        printerr("Wrote output file: " + output_json)
