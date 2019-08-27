#!/usr/bin/env python3

import argparse
import copy
import difflib
import json
import sys
import tempfile
import yaml

from pyk.kast    import _notif, _warning, _fatal
from pyk.kast      import combineDicts, appliedLabelStr, constLabel, underbarUnparsing, K_symbols, KApply, KConstant, KSequence, KVariable, KToken
from buildConfig import *
from pathlib import Path

bitListTerm = lambda inputInt: listOf('Bit', converter=intToBoolToken)([i for i in bin(int(inputInt, 16))[2:]])
bytesListTerm = listOf('Bytes', converter = hashToken)

forkTerm = labelWithKeyPairs('#Fork' , [ ('previous_version' , hashToken)
                                       , ('current_version'  , hashToken)
                                       , ('epoch'            , intToken)
                                       ]
                            )

checkpointTerm = labelWithKeyPairs('#Checkpoint' , [ ('epoch' , intToken)
                                                   , ('root'  , hashToken)
                                                   ]
                                  )

validatorTerm = labelWithKeyPairs('#Validator' , [ ('pubkey'                       , hashToken)
                                                 , ('withdrawal_credentials'       , hashToken)
                                                 , ('effective_balance'            , intToken)
                                                 , ('slashed'                      , boolToken)
                                                 , ('activation_eligibility_epoch' , intToken)
                                                 , ('activation_epoch'             , intToken)
                                                 , ('exit_epoch'                   , intToken)
                                                 , ('withdrawable_epoch'           , intToken)
                                                 ]
                                 )

crosslinkTerm = labelWithKeyPairs('#Crosslink' , [ ('shard'       , intToken)
                                                 , ('parent_root' , hashToken)
                                                 , ('start_epoch' , intToken)
                                                 , ('end_epoch'   , intToken)
                                                 , ('data_root'   , hashToken)
                                                 ]
                                 )

attestationDataTerm = labelWithKeyPairs('#AttestationData' , [ ('beacon_block_root' , hashToken)
                                                             , ('source'            , checkpointTerm)
                                                             , ('target'            , checkpointTerm)
                                                             , ('crosslink'         , crosslinkTerm)
                                                             ]
                                       )

indexedAttestationTerm = labelWithKeyPairs('#IndexedAttestation' , [ ('custody_bit_0_indices' , listOf('Int', converter = intToken))
                                                                   , ('custody_bit_1_indices' , listOf('Int', converter = intToken))
                                                                   , ('data'                  , attestationDataTerm)
                                                                   , ('signature'             , hashToken)
                                                                   ]
                                          )

depositDataTerm = labelWithKeyPairs('#DepositData' , [ ('pubkey'                 , hashToken)
                                                     , ('withdrawal_credentials' , hashToken)
                                                     , ('amount'                 , intToken)
                                                     , ('signature'              , hashToken)
                                                     ]
                                   )

blockheaderTerm = labelWithKeyPairs('#BeaconBlockHeader' , [ ('slot'        , intToken)
                                                           , ('parent_root' , hashToken)
                                                           , ('state_root'  , hashToken)
                                                           , ('body_root'   , hashToken)
                                                           , ('signature'   , hashToken)
                                                           ]
                                   )

proposerSlashingTerm = labelWithKeyPairs('#ProposerSlashing' , [ ('proposer_index' , intToken)
                                                               , ('header_1'       , blockheaderTerm)
                                                               , ('header_2'       , blockheaderTerm)
                                                               ]
                                        )

attesterSlashingTerm = labelWithKeyPairs('#AttesterSlashing' , [ ('attestation_1' , indexedAttestationTerm)
                                                               , ('attestation_2' , indexedAttestationTerm)
                                                               ]
                                        )

# #Attestation( BitList, AttestationData, BitList, BLSSignature )
attestationTerm = labelWithKeyPairs('#Attestation' , [ ('aggregation_bits' , bitListTerm)
                                                     , ('data'             , attestationDataTerm)
                                                     , ('custody_bits'     , bitListTerm)
                                                     , ('signature'        , hashToken)
                                                     ]
                                   )

depositTerm = labelWithKeyPairs('#Deposit' , [ ('proof' , bytesListTerm)
                                             , ('data' , depositDataTerm)
                                             ]
                               )

voluntaryExitTerm = labelWithKeyPairs('#VoluntaryExit' , [ ('epoch'           , intToken)
                                                         , ('validator_index' , intToken)
                                                         , ('signature'       , hashToken)
                                                         ]
                                     )

eth1dataTerm = labelWithKeyPairs('#Eth1Data' , [ ('deposit_root'  , hashToken)
                                               , ('deposit_count' , intToken)
                                               , ('block_hash'    , hashToken)
                                               ]
                                )

pendingAttestationTerm = labelWithKeyPairs('#PendingAttestation' , [ ('aggregation_bits' , bitListTerm)
                                                                   , ('data'             , attestationDataTerm)
                                                                   , ('inclusion_delay'  , intToken)
                                                                   , ('proposer_index'   , intToken)
                                                                   ]
                                          )

transferTerm = labelWithKeyPairs('#Transfer' , [ ('sender'    , intToken)
                                               , ('recipient' , intToken)
                                               , ('amount'    , intToken)
                                               , ('fee'       , intToken)
                                               , ('slot'      , intToken)
                                               , ('pubkey'    , hashToken)
                                               , ('signature' , hashToken)
                                               ]
                                )

test_type_to_term = {
    'proposer_slashing': proposerSlashingTerm,
    'attester_slashing': attesterSlashingTerm,
    'attestation'      : attestationTerm,
    'deposit'          : depositTerm,
    'voluntary_exit'   : voluntaryExitTerm,
    'transfer'         : transferTerm
}

init_config_cells = { 'GENESIS_TIME_CELL'                  : (['genesis_time']                       , intToken)
                    , 'SLOT_CELL'                          : (['slot']                               , intToken)
                    , 'FORK_CELL'                          : (['fork']                               , forkTerm)
                    , 'LATEST_BLOCK_HEADER_CELL'           : (['latest_block_header']                , blockheaderTerm)
                    , 'BLOCK_ROOTS_CELL'                   : (['block_roots']                        , indexedMapOf(converter = hashToken))
                    , 'STATE_ROOTS_CELL'                   : (['state_roots']                        , indexedMapOf(converter = hashToken))
                    , 'HISTORICAL_ROOTS_CELL'              : (['historical_roots']                   , bytesListTerm)
                    , 'ETH1_DATA_CELL'                     : (['eth1_data']                          , eth1dataTerm)
                    , 'ETH1_DATA_VOTES_CELL'               : (['eth1_data_votes']                    , listOf('Eth1Data', converter = eth1dataTerm))
                    , 'ETH1_DEPOSIT_INDEX_CELL'            : (['eth1_deposit_index']                 , intToken)
                    , 'VALIDATORS_CELL'                    : (['validators']                         , indexedMapOf(converter = validatorTerm))
                    , 'BALANCES_CELL'                      : (['balances']                           , indexedMapOf(converter = intToken))
                    , 'START_SHARD_CELL'                   : (['start_shard']                        , intToken)
                    , 'RANDAO_MIXES_CELL'                  : (['randao_mixes']                       , bytesListTerm)
                    , 'ACTIVE_INDEX_ROOTS_CELL'            : (['active_index_roots']                 , bytesListTerm)
                    , 'COMPACT_COMMITTEES_ROOTS_CELL'      : (['compact_committees_roots']           , bytesListTerm)
                    , 'SLASHINGS_CELL'                     : (['slashings']                          , indexedMapOf(converter = intToken))
                    , 'PREVIOUS_EPOCH_ATTESTATION_CELL'    : (['previous_epoch_attestations']        , listOf('PendingAttestation', converter = pendingAttestationTerm))
                    , 'CURRENT_EPOCH_ATTESTATIONS_CELL'    : (['current_epoch_attestations']         , listOf('PendingAttestation', converter = pendingAttestationTerm))
                    , 'PREVIOUS_CROSSLINKS_CELL'           : (['previous_crosslinks']                , indexedMapOf(converter = crosslinkTerm))
                    , 'CURRENT_CROSSLINKS_CELL'            : (['current_crosslinks']                 , indexedMapOf(converter = crosslinkTerm))
                    , 'JUSTIFICATION_BITS_CELL'            : (['justification_bits']                 , bitListTerm)
                    , 'PREVIOUS_JUSTIFIED_CHECKPOINT_CELL' : (['previous_justified_checkpoint']      , checkpointTerm)
                    , 'CURRENT_JUSTIFIED_CHECKPOINT_CELL'  : (['current_justified_checkpoint']       , checkpointTerm)
                    , 'FINALIZED_CHECKPOINT_CELL'          : (['finalized_checkpoint']               , checkpointTerm)
                    # Later: only when test 2nd arg is a Block.
                    # , 'BLOCKSLOT_CELL'                     : (['latest_block_header', 'slot']        , intToken)
                    # , 'PARENT_ROOT_CELL'                   : (['latest_block_header', 'parent_root'] , hashToken)
                    # , 'STATE_ROOT_CELL'                    : (['latest_block_header', 'state_root']  , hashToken)
                    # , 'SIGNATURE_CELL'                     : (['latest_block_header', 'signature']   , hashToken)
                    # , 'TRANSFERS_CELL'                     : (['transfers']                          , listOf('Transfer', converter = transferTerm))
                    }

def getKeyChain(yaml_input, key_chain):
    output = copy.deepcopy(yaml_input)
    for key in key_chain:
        if key in output:
            output = output[key]
        else:
            return None
    return output

def gatherKeyChains(yaml_input):
    if type(yaml_input) is not dict:
        return []
    key_chains = []
    for k in yaml_input.keys():
        sub_key_chains = gatherKeyChains(yaml_input[k])
        if len(sub_key_chains) == 0:
            key_chains.append([k])
        else:
            for sub_key_chain in sub_key_chains:
                key_chains.append([k] + sub_key_chain)
    return key_chains


def buildInitConfigSubstitution(test_pre_state, key_table = init_cells, skip_keys = [], debug_keys = []):
    new_key_table = {}
    used_key_chains = []
    for cell_var in key_table:
        if cell_var in init_config_cells and cell_var not in skip_keys:
            (pre_keys, converter) = init_config_cells[cell_var]
            test_field = getKeyChain(test_pre_state, pre_keys)
            if test_field is None:
                new_key_table[cell_var] = key_table[cell_var]
                _warning('Key not found: ' + str(pre_keys))
            else:
                kast_term = converter(getKeyChain(test_pre_state, pre_keys))
                if cell_var in debug_keys:
                    _notif(cell_var)
                    printerr(str(kast_term))
                    printerr(prettyPrintKast(kast_term, ALL_symbols))
                new_key_table[cell_var] = kast_term
                used_key_chains.append(pre_keys)
        else:
            new_key_table[cell_var] = key_table[cell_var]
            _warning('Unset configuration variable: ' + cell_var)
    for pre_key in gatherKeyChains(test_pre_state):
        if pre_key not in used_key_chains:
            _warning('Unused pre_key: ' + str(pre_key))

    return new_key_table


def loadYamlOperation(operation):
    operation_file = Path.joinpath(Path(args.pre.name).parent, "%s.yaml" % operation).as_posix()
    print("Operation file: %s\n" % operation_file)
    return yaml.load(open(operation_file, 'r'), Loader=yaml.FullLoader)


def loadPostYaml():
    try:
        post_file = Path.joinpath(Path(args.pre.name).parent, "post.yaml").as_posix()
        result = yaml.load(open(post_file, 'r'), Loader=yaml.FullLoader)
        print("\nPost file: %s\n" % post_file)
        return result
    except FileNotFoundError:
        print("\nNo post file")
        return None


if __name__ == '__main__':

    arguments = argparse.ArgumentParser(prog = sys.argv[0])
    arguments.add_argument('command'  , choices = ['parse'])
    arguments.add_argument('-o', '--output' , type = argparse.FileType('w'), default = '-')
    arguments.add_argument('--pre'  , type = argparse.FileType('r'), default = '-')
    arguments.add_argument('-d', '--debug', dest='debug', action='store_true')

    args = arguments.parse_args()

    yaml_pre = yaml.load(args.pre, Loader = yaml.FullLoader)
    test_title = args.pre.name
    _notif(test_title)

    # TODO bls_setting is in meta.yaml
    if 'bls_setting' in yaml_pre and yaml_pre['bls_setting'] > 1:
        _warning('Skipping test with `bls_setting` set to ' + str(yaml_pre['bls_setting']))

    all_keys = list(init_cells.keys())

    skip_keys = [
                #  'GENESIS_TIME_CELL'
                #, 'SLOT_CELL'
                #, 'FORK_CELL'
                #, 'LATEST_BLOCK_HEADER_CELL'
                #, 'BLOCK_ROOTS_CELL'
                #, 'STATE_ROOTS_CELL'
                #, 'HISTORICAL_ROOTS_CELL'
                #, 'ETH1_DATA_CELL'
                #, 'ETH1_DATA_VOTES_CELL'
                #, 'ETH1_DEPOSIT_INDEX_CELL'
                #, 'VALIDATORS_CELL'
                #, 'BALANCES_CELL'
                #, 'START_SHARD_CELL'
                #, 'RANDAO_MIXES_CELL'
                #, 'ACTIVE_INDEX_ROOTS_CELL'
                #, 'COMPACT_COMMITTEES_ROOTS_CELL'
                #, 'SLASHINGS_CELL'
                #, 'PREVIOUS_EPOCH_ATTESTATION_CELL'
                #, 'CURRENT_EPOCH_ATTESTATIONS_CELL'
                #, 'PREVIOUS_CROSSLINKS_CELL'
                #, 'CURRENT_CROSSLINKS_CELL'
                #, 'JUSTIFICATION_BITS_CELL'
                #, 'PREVIOUS_JUSTIFIED_CHECKPOINT_CELL'
                #, 'CURRENT_JUSTIFIED_CHECKPOINT_CELL'
                #, 'FINALIZED_CHECKPOINT_CELL'
                #, 'BLOCKSLOT_CELL'
                #, 'PARENT_ROOT_CELL'
                #, 'STATE_ROOT_CELL'
                #, 'SIGNATURE_CELL'
                #, 'TRANSFERS_CELL'
                ]

    debug_keys = [ ]
    init_config_subst = buildInitConfigSubstitution(yaml_pre, skip_keys = skip_keys, debug_keys = debug_keys)

    # build <k> cell
    test_type = Path(args.pre.name).parts[-4]
    if test_type not in test_type_to_term.keys():
        raise Exception("Invalid test type: " + test_type)
    yaml_operation = loadYamlOperation(test_type)
    init_config_subst['K_CELL'] = KApply('process_%s' % test_type, [test_type_to_term[test_type](yaml_operation)])

    init_config = substitute(symbolic_configuration, init_config_subst)
    kast_json = { 'format' : 'KAST' , 'version' : 1.0 , 'term' : init_config }

    with tempfile.NamedTemporaryFile(mode = 'w', delete = not args.debug) as tempf:
        json.dump(kast_json, tempf)
        tempf.flush()

        fastPrinted = prettyPrintKast(init_config['args'][0], ALL_symbols).strip()
        (returnCode, kastPrinted, _) = kast(tempf.name, '--input', 'json', '--output', 'pretty', '--debug')
        if returnCode != 0:
            _fatal('kast returned non-zero exit code: ' + test_title, code = returnCode)

        kastPrinted = kastPrinted.strip()
        if fastPrinted != kastPrinted:
            _warning('kastPrinted and fastPrinted differ!')
            for line in difflib.unified_diff(kastPrinted.split('\n'), fastPrinted.split('\n'), fromfile='kast', tofile='fast', lineterm='\n'):
                sys.stderr.write(line + '\n')
            sys.stderr.flush()

        (returnCode, _, _) = krun(tempf.name, '--term', '--parser', 'cat')
        if returnCode != 0:
            _fatal('krun returned non-zero exit code: ' + test_title, code = returnCode)

    # Printing the post state
    post_json = loadPostYaml()
    if post_json is not None:
        post_config_subst = buildInitConfigSubstitution(post_json, skip_keys = skip_keys, debug_keys = debug_keys)
        # todo use a copy of symbolic configuration?
        post_config = substitute(symbolic_configuration, post_config_subst)
        post_kast_json = { 'format' : 'KAST' , 'version' : 1.0 , 'term' : post_config }
        with tempfile.NamedTemporaryFile(mode = 'w', delete = not args.debug) as tempf:
            json.dump(post_kast_json, tempf)
            tempf.flush()

            (returnCode, kastPrinted, _) = kast(tempf.name, '--input', 'json', '--output', 'pretty', '--debug')
            if returnCode != 0:
                _fatal('kast returned non-zero exit code: ' + test_title, code = returnCode)

            kastPrinted = kastPrinted.strip()
