#!/usr/bin/env python3

import argparse
import json
import sys
import tempfile
import yaml

from buildConfig import *

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
           , "block_roots"                   : ('BLOCK_ROOTS_CELL'                , indexedMapOf("Bytes32"))
           , "state_roots"                   : ('STATE_ROOTS_CELL'                , indexedMapOf("Bytes32"))
           , "historical_roots"              : ('HISTORICAL_ROOTS_CELL'           , listOf("Hash", converter = intToken))
           , "eth1_data"                     : ('ETH1_DATA_CELL'                  , eth1dataTerm)
           , "eth1_data_votes"               : ('ETH1_DATA_VOTES_CELL'            , listOf("Eth1Data", converter = eth1dataTerm))
           , "eth1_deposit_index"            : ('ETH1_DEPOSIT_INDEX_CELL'         , intToken)
           , "validators"                    : ('VALIDATORS_CELL'                 , indexedMapOf(validatorTerm))
           , "balances"                      : ('BALANCES_CELL'                   , indexedMapOf(intToken))
           , "start_shard"                   : ('START_SHARD_CELL'                , intToken)
           , "randao_mixes"                  : ('RANDAO_MIXES_CELL'               , listOf("Hash", converter = hexIntToken))
           , "active_index_roots"            : ('ACTIVE_INDEX_ROOTS_CELL'         , listOf("Hash", converter = hexIntToken))
           , "compact_committees_roots"      : ('COMPACT_COMMITTEES_ROOTS'        , listOf("Hash", converter = hexIntToken))
           , "slashings"                     : ('SLASHINGS'                       , indexedMapOf(intToken))
           , "previous_epoch_attestations"   : ('PREVIOUS_EPOCH_ATTESTATION_CELL' , listOf("PendingAttestation", converter = pendingAttestationTerm))
           , "current_epoch_attestations"    : ('CURRENT_EPOCH_ATTESTATIONS_CELL' , listOf("PendingAttestation", converter = pendingAttestationTerm))
           , "previous_crosslinks"           : ('PREVIOUS_CROSSLINKS_CELL'        , indexedMapOf(crosslinkTerm))
           , "current_crosslinks"            : ('CURRENT_CROSSLINKS_CELL'         , indexedMapOf(crosslinkTerm))
           , "justification_bits"            : ('JUSTIFICATION_BITS'              , listOf("Uint64", converter = intToken))
           , "previous_justified_checkpoint" : ('PREVIOUS_JUSTIFIED_CHECKPOINT'   , checkpointTerm)
           , "current_justified_checkpoint"  : ('CURRENT_JUSTIFIED_CHECKPOINT'    , checkpointTerm)
           , "finalized_checkpoint"          : ('FINALIZED_CHECKPOINT'            , checkpointTerm)
           }

def buildInitConfigSubstitution(test_pre_state, key_table = init_cells, skip_keys = []):
    new_key_table = key_table
    for pre_key in test_pre_state.keys():
        test_pre = test_pre_state[pre_key]
        if pre_key in pre_keys:
            (cell_var, converter) = pre_keys[pre_key]
            if cell_var in new_key_table and cell_var not in skip_keys:
                new_key_table[cell_var] = converter(test_pre)
            else:
                printerr("unimplemented pre-key: " + str(pre_key) + " -> " + str(test_pre))
        elif len(str(test_pre)) < 3:
            printerr("unused pre-key: " + pre_key)
    return new_key_table

if __name__ == "__main__":

    arguments = argparse.ArgumentParser(prog = sys.argv[0])
    arguments.add_argument('command'  , choices = ['parse'])
    arguments.add_argument('-i', '--input'  , type = argparse.FileType('r'), default = '-')
    arguments.add_argument('-o', '--output' , type = argparse.FileType('w'), default = '-')

    args = arguments.parse_args()

    yaml_test = yaml.load(args.input, Loader = yaml.FullLoader)

    for test_case in yaml_test['test_cases'][17:]:
        printerr("test file: " + args.input.name)
        printerr("test description: " + test_case['description'])
        all_keys = init_cells.keys()
        init_config_subst = buildInitConfigSubstitution(test_case['pre'])

        if 'transfer' in test_case:
            printerr("Skipping transfer block!")

        if test_case['post'] is None:
            printerr("No post condition!")
        else:
            printerr("Skipping post block!")

        kast_json = { "format"  : "KAST"
                    , "version" : 1.0
                    , "term"    : substitute(symbolic_configuration, init_config_subst)
                    }

        with tempfile.NamedTemporaryFile(mode = "w", delete = False) as tempf:
            json.dump(kast_json, tempf)
            tempf.flush()
            (returnCode, _, _) = krun(tempf.name, "--term", "--parser", "cat")
            if returnCode != 0:
                printerr("[FATAL] krun return non-zero exit code: " + args.input.name + " " + test_case["description"])
                sys.exit(returnCode)
