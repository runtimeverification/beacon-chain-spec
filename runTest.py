#!/usr/bin/env python3

import argparse
import difflib
import json
import sys
import tempfile
import yaml

from pyk.kast    import _fatal
from buildConfig import *

forkTerm = labelWithKeyPairs('#Fork' , [ ('previous_version' , hexIntToken)
                                       , ('current_version'  , hexIntToken)
                                       , ('epoch'            , intToken)
                                       ]
                            )

checkpointTerm = labelWithKeyPairs('#Checkpoint' , [ ('epoch' , intToken)
                                                   , ('root'  , hexIntToken)
                                                   ]
                                  )

validatorTerm = labelWithKeyPairs('#Validator' , [ ('pubkey'                       , hexIntToken)
                                                 , ('withdrawal_credentials'       , hexIntToken)
                                                 , ('effective_balance'            , intToken)
                                                 , ('slashed'                      , boolToken)
                                                 , ('activation_eligibility_epoch' , intToken)
                                                 , ('activation_epoch'             , intToken)
                                                 , ('exit_epoch'                   , intToken)
                                                 , ('withdrawable_epoch'           , intToken)
                                                 ]
                                 )

crosslinkTerm = labelWithKeyPairs('#Crosslink' , [ ('shard'       , intToken)
                                                 , ('parent_root' , hexIntToken)
                                                 , ('start_epoch' , intToken)
                                                 , ('end_epoch'   , intToken)
                                                 , ('data_root'   , hexIntToken)
                                                 ]
                                 )

blockheaderTerm = labelWithKeyPairs('#BeaconBlockHeader' , [ ('slot'        , intToken)
                                                           , ('parent_root' , hexIntToken)
                                                           , ('state_root'  , hexIntToken)
                                                           , ('body_root'   , hexIntToken)
                                                           , ('signature'   , hexIntToken)
                                                           ]
                                   )

eth1dataTerm = labelWithKeyPairs('#Eth1Data' , [ ('deposit_root'  , hexIntToken)
                                               , ('deposit_count' , intToken)
                                               , ('block_hash'    , hexIntToken)
                                               ]
                                )

attestationDataTerm = labelWithKeyPairs('#AttestationData' , [ ('beacon_block_root' , hexIntToken)
                                                             , ('source'            , checkpointTerm)
                                                             , ('target'            , checkpointTerm)
                                                             , ('crosslink'         , crosslinkTerm)
                                                             ]
                                       )

pendingAttestationTerm = labelWithKeyPairs('#PendingAttestation' , [ ('aggregation_bits'     , listOf('Bit', converter = intToken))
                                                                   , ('data'                 , attestationDataTerm)
                                                                   , ('inclusion_delay'      , intToken)
                                                                   , ('proposer_index'       , intToken)
                                                                   ]
                                          )

init_config_cells = { 'GENESIS_TIME_CELL'                  : ('genesis_time'                  , intToken)
                    , 'SLOT_CELL'                          : ('slot'                          , intToken)
                    , 'FORK_CELL'                          : ('fork'                          , forkTerm)
                    , 'LATEST_BLOCK_HEADER_CELL'           : ('latest_block_header'           , blockheaderTerm)
                    , 'BLOCK_ROOTS_CELL'                   : ('block_roots'                   , indexedMapOf(converter = hexIntToken))
                    , 'STATE_ROOTS_CELL'                   : ('state_roots'                   , indexedMapOf(converter = hexIntToken))
                    , 'HISTORICAL_ROOTS_CELL'              : ('historical_roots'              , listOf('Hash', converter = hexIntToken))
                    , 'ETH1_DATA_CELL'                     : ('latest_eth1_data'              , eth1dataTerm)
                    , 'ETH1_DATA_VOTES_CELL'               : ('eth1_data_votes'               , listOf('Eth1Data', converter = eth1dataTerm))
                    , 'ETH1_DEPOSIT_INDEX_CELL'            : ('deposit_index'                 , intToken)
                    , 'VALIDATORS_CELL'                    : ('validator_registry'            , indexedMapOf(converter = validatorTerm))
                    , 'BALANCES_CELL'                      : ('balances'                      , indexedMapOf(converter = intToken))
                    , 'START_SHARD_CELL'                   : ('latest_start_shard'            , intToken)
                    , 'RANDAO_MIXES_CELL'                  : ('randao_mixes'                  , listOf('Hash', converter = hexIntToken))
                    , 'ACTIVE_INDEX_ROOTS_CELL'            : ('active_index_roots'            , listOf('Hash', converter = hexIntToken))
                    , 'COMPACT_COMMITTEES_ROOTS_CELL'      : ('compact_committees_roots'      , listOf('Hash', converter = hexIntToken))
                    , 'SLASHINGS_CELL'                     : ('slashings'                     , indexedMapOf(converter = intToken))
                    , 'PREVIOUS_EPOCH_ATTESTATION_CELL'    : ('previous_epoch_attestations'   , listOf('PendingAttestation', converter = pendingAttestationTerm))
                    , 'CURRENT_EPOCH_ATTESTATIONS_CELL'    : ('current_epoch_attestations'    , listOf('PendingAttestation', converter = pendingAttestationTerm))
                    , 'PREVIOUS_CROSSLINKS_CELL'           : ('previous_crosslinks'           , indexedMapOf(converter = crosslinkTerm))
                    , 'CURRENT_CROSSLINKS_CELL'            : ('current_crosslinks'            , indexedMapOf(converter = crosslinkTerm))
                    , 'JUSTIFICATION_BITS_CELL'            : ('justification_bitfield'        , intToken)
                    , 'PREVIOUS_JUSTIFIED_CHECKPOINT_CELL' : ('previous_justified_checkpoint' , checkpointTerm)
                    , 'CURRENT_JUSTIFIED_CHECKPOINT_CELL'  : ('current_justified_checkpoint'  , checkpointTerm)
                    , 'FINALIZED_CHECKPOINT_CELL'          : ('finalized_checkpoint'          , checkpointTerm)
                    }

def buildInitConfigSubstitution(test_pre_state, key_table = init_cells, skip_keys = []):
    new_key_table = {}
    used_pre_keys = []
    for cell_var in key_table:
        if cell_var in init_config_cells and cell_var not in skip_keys:
            (pre_key, converter) = init_config_cells[cell_var]
            if pre_key in test_pre_state:
                new_key_table[cell_var] = converter(test_pre_state[pre_key])
                used_pre_keys.append(pre_key)
            else:
                printerr('Not in test_pre_state: ' + pre_key)
        else:
            new_key_table[cell_var] = key_table[cell_var]
            printerr('Unset configuration variable: ' + cell_var)
    for pre_key in set(test_pre_state.keys()).difference(set(used_pre_keys)):
        printerr('Unused pre_key: ' + pre_key)
    return new_key_table

if __name__ == '__main__':

    arguments = argparse.ArgumentParser(prog = sys.argv[0])
    arguments.add_argument('command'  , choices = ['parse'])
    arguments.add_argument('-i', '--input'  , type = argparse.FileType('r'), default = '-')
    arguments.add_argument('-o', '--output' , type = argparse.FileType('w'), default = '-')

    args = arguments.parse_args()

    yaml_test = yaml.load(args.input, Loader = yaml.FullLoader)

    for test_case in yaml_test['test_cases']:
        test_title = test_case['description'] + ' from ' + args.input.name
        printerr('')
        printerr(test_title)
        printerr('='.join(['' for i in test_title + ' ']))
        printerr
        all_keys = init_cells.keys()
        init_config_subst = buildInitConfigSubstitution(test_case['pre'])

        if 'transfer' in test_case:
            printerr('Skipping transfer block!')

        if test_case['post'] is None:
            printerr('No post condition!')
        else:
            printerr('Skipping post block!')

        init_config = substitute(symbolic_configuration, init_config_subst)
        fastPrinted = prettyPrintKast(init_config['args'][0], ALL_symbols).strip()

        kast_json = { 'format' : 'KAST' , 'version' : 1.0 , 'term' : init_config }

        with tempfile.NamedTemporaryFile(mode = 'w') as tempf:
            json.dump(kast_json, tempf)
            tempf.flush()
            (returnCode, kastPrinted, _) = kast(tempf.name, '--input', 'json', '--output', 'pretty')
            kastPrinted = kastPrinted.strip()
            if fastPrinted != kastPrinted:
                printerr('Diff: ')
                for line in difflib.unified_diff(kastPrinted.split('\n'), fastPrinted.split('\n'), fromfile='kast', tofile='fast', lineterm='\n'):
                    print(line)
                _fatal('kastPrinted and fastPrinted differ!')
            (returnCode, _, _) = krun(tempf.name, '--term', '--parser', 'cat')
            if returnCode != 0:
                _fatal('krun returned non-zero exit code: ' + args.input.name + ' ' + test_case['description'])
                sys.exit(returnCode)
