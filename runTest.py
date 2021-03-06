#!/usr/bin/env python3

import re
import argparse
import copy
import difflib

import yaml

from pyk.kast    import _notif, _warning, _fatal
from pyk.kast      import KApply, KSequence
from buildConfig import *
from pathlib import Path

JUSTIFICATION_BITS_LENGTH = 4

# Adapted from:
# https://github.com/ethereum/py-ssz/blob/938fbdb931576b75813e7bf660cfd66f06482b84/ssz/sedes/bitlist.py#L66-L76
def deserializeBitlist(hex_string: str):
    data = bytearray.fromhex(hex_string[2:])
    as_integer = int.from_bytes(data, 'little')
    len_value = as_integer.bit_length() - 1
    return [bool((data[bit_index // 8] >> bit_index % 8) % 2) for bit_index in range(len_value)]

def deserializeBitvector(hex_string: str, bit_count: int):
    data = bytearray.fromhex(hex_string[2:])
    return [bool((data[bit_index // 8] >> bit_index % 8) % 2) for bit_index in range(bit_count)]

bitListTerm = lambda hex_string: listOf('Bit', converter = boolToBoolStringToken)(deserializeBitlist(hex_string))

bitVectorTerm = lambda bit_count: lambda hex_string: \
    listOf('Bit', converter = boolToBoolStringToken)(deserializeBitvector(hex_string, bit_count))

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

attestationDataTerm = labelWithKeyPairs('#AttestationData' , [ ('slot' , intToken)
                                                             , ('index' , intToken)
                                                             , ('beacon_block_root' , hashToken)
                                                             , ('source'            , checkpointTerm)
                                                             , ('target'            , checkpointTerm)
                                                             ]
                                       )

indexedAttestationTerm = labelWithKeyPairs('#IndexedAttestation' , [ ('attesting_indices' , listOf('Int', converter = intToken))
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

depositMessageTerm = labelWithKeyPairs('#DepositMessage' , [ ('pubkey'                 , hashToken)
                                                           , ('withdrawal_credentials' , hashToken)
                                                           , ('amount'                 , intToken)
                                                     ]
                                   )

beaconBlockHeaderTerm = labelWithKeyPairs('#BeaconBlockHeader', [ ('slot'        , intToken)
                                                                , ('parent_root' , hashToken)
                                                                , ('state_root'  , hashToken)
                                                                , ('body_root'   , hashToken)
                                                                ]
                                          )

signedBeaconBlockHeaderTerm = labelWithKeyPairs('#SignedBeaconBlockHeader' , [ ('message'   , beaconBlockHeaderTerm)
                                                                           ,   ('signature' , hashToken)
                                                                             ]
                                               )


proposerSlashingTerm = labelWithKeyPairs('#ProposerSlashing' , [ ('proposer_index' , intToken)
                                                               , ('signed_header_1'       , signedBeaconBlockHeaderTerm)
                                                               , ('signed_header_2'       , signedBeaconBlockHeaderTerm)
                                                               ]
                                        )

attesterSlashingTerm = labelWithKeyPairs('#AttesterSlashing' , [ ('attestation_1' , indexedAttestationTerm)
                                                               , ('attestation_2' , indexedAttestationTerm)
                                                               ]
                                        )

# class Attestation(Container):
#     aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
#     data: AttestationData
#     signature: BLSSignature
attestationTerm = labelWithKeyPairs('#Attestation' , [ ('aggregation_bits' , bitListTerm)
                                                     , ('data'             , attestationDataTerm)
                                                     , ('signature'        , hashToken)
                                                     ]
                                   )

depositTerm = labelWithKeyPairs('#Deposit' , [ ('proof' , bytesListTerm)
                                             , ('data' , depositDataTerm)
                                             ]
                               )

voluntaryExitTerm = labelWithKeyPairs('#VoluntaryExit' , [ ('epoch'           , intToken)
                                                         , ('validator_index' , intToken)
                                                         ]
                                     )

signedVoluntaryExitTerm = labelWithKeyPairs('#SignedVoluntaryExit' , [ ('message'   , voluntaryExitTerm)
                                                                   ,   ('signature' , hashToken)
                                                                   ]
                                           )


eth1DataTerm = labelWithKeyPairs('#Eth1Data', [ ('deposit_root'  , hashToken)
                                              , ('deposit_count' , intToken)
                                              , ('block_hash'    , hashToken)
                                              ]
                                )

eth1BlockTerm = labelWithKeyPairs('#Eth1Block', [ ('timestamp'  , intToken)
                                                ]
                                )

historicalBatchTerm = labelWithKeyPairs('#HistoricalBatch', [ ('block_roots' , bytesListTerm)
                                                            , ('state_roots' , bytesListTerm)
                                                            ]
                                       )

# class PendingAttestation(Container):
#     aggregation_bits: Bitlist[MAX_VALIDATORS_PER_COMMITTEE]
#     data: AttestationData
#     inclusion_delay: Slot
#     proposer_index: ValidatorIndex
pendingAttestationTerm = labelWithKeyPairs('#PendingAttestation' , [ ('aggregation_bits' , bitListTerm)
                                                                   , ('data'             , attestationDataTerm)
                                                                   , ('inclusion_delay'  , intToken)
                                                                   , ('proposer_index'   , intToken)
                                                                   ]
                                          )

beaconBlockBodyTerm = labelWithKeyPairs('#BeaconBlockBody' , [ ('randao_reveal'          , hashToken)
                                                             , ('eth1_data'              , eth1DataTerm)
                                                             , ('graffiti'               , hashToken)
                                                             , ('proposer_slashings'     , listOf('ProposerSlashing', converter = proposerSlashingTerm))
                                                             , ('attester_slashings'     , listOf('AttesterSlashing', converter = attesterSlashingTerm))
                                                             , ('attestations'           , listOf('Attestation', converter = attestationTerm))
                                                             , ('deposits'               , listOf('Deposit', converter = depositTerm))
                                                             , ('voluntary_exits' , listOf('SignedVoluntaryExit', converter = signedVoluntaryExitTerm))
                                                             ]
                                       )

beaconBlockTerm = labelWithKeyPairs('#BeaconBlock' , [ ('slot'          , intToken)
                                                     , ('parent_root'   , hashToken)
                                                     , ('state_root'    , hashToken)
                                                     , ('body'          , beaconBlockBodyTerm)
                                                     ]
                                   )
aggregateAndProofTerm = labelWithKeyPairs('#AggregateAndProof' , [ ('aggregator_index'           , intToken)
                                                                 , ('aggregate'       , attestationTerm)
                                                                 , ('selection_proof' , hashToken)
                                                                 ]
                                         )

signedBeaconBlockTerm = labelWithKeyPairs('#SignedBeaconBlock' , [ ('message'   , beaconBlockTerm)
                                                               ,   ('signature' , hashToken)
                                                                 ]
                                         )

signingRootTerm = labelWithKeyPairs('#SigningRoot' , [ ('object_root' , hashToken)
                                                   ,   ('domain'      , hashToken)
                                                     ]
                                   )

test_type_to_term = {
    # operations
    'proposer_slashing': proposerSlashingTerm,
    'attester_slashing': attesterSlashingTerm,
    'attestation'      : attestationTerm,
    'deposit'          : depositTerm,
    'voluntary_exit'   : signedVoluntaryExitTerm,

    'block_header'     : beaconBlockTerm,

    # epoch_processing
    'final_updates'                     : None,
    'justification_and_finalization'    : None,
    'registry_updates'                  : None,
    'slashings'                         : None,
    'rewards_and_penalties'             : None, #planned

    # sanity
    'slots'                             : intToken,

    # genesis
    'validity'                          : None
}

data_class_to_converter = {
    'Attestation': attestationTerm,
    'AttestationData': attestationDataTerm,
    'AttesterSlashing': attesterSlashingTerm,
    'BeaconBlock': beaconBlockTerm,
    'BeaconBlockBody': beaconBlockBodyTerm,
    'SignedBeaconBlock': signedBeaconBlockTerm,
    'BeaconBlockHeader': beaconBlockHeaderTerm,
    'SignedBeaconBlockHeader': signedBeaconBlockHeaderTerm,
    'BeaconState': None,
    'Checkpoint': checkpointTerm,
    'Deposit': depositTerm,
    'DepositData': depositDataTerm,
    'DepositMessage': depositMessageTerm,
    'Eth1Data': eth1DataTerm,
    'Eth1Block': eth1BlockTerm,
    'Fork': forkTerm,
    'HistoricalBatch': historicalBatchTerm,
    'IndexedAttestation': indexedAttestationTerm,
    'PendingAttestation': pendingAttestationTerm,
    'ProposerSlashing': proposerSlashingTerm,
    'Validator': validatorTerm,
    'VoluntaryExit': voluntaryExitTerm,
    'SignedVoluntaryExit': signedVoluntaryExitTerm,
    'AggregateAndProof' : aggregateAndProofTerm,
    'SigningRoot' : signingRootTerm,
}

init_config_cells = { 'GENESIS_TIME_CELL'                  : (['genesis_time']                       , intToken)
                    , 'SLOT_CELL'                          : (['slot']                               , intToken)
                    , 'FORK_CELL'                          : (['fork']                               , forkTerm)
                    , 'LATEST_BLOCK_HEADER_CELL'           : (['latest_block_header']                , beaconBlockHeaderTerm)
                    , 'BLOCK_ROOTS_CELL'                   : (['block_roots']                        , indexedMapOf(converter = hashToken))
                    , 'STATE_ROOTS_CELL'                   : (['state_roots']                        , indexedMapOf(converter = hashToken))
                    , 'HISTORICAL_ROOTS_CELL'              : (['historical_roots']                   , bytesListTerm)
                    , 'ETH1_DATA_CELL'                     : (['eth1_data']                          , eth1DataTerm)
                    , 'ETH1_DATA_VOTES_CELL'               : (['eth1_data_votes']                    , listOf('Eth1Data', converter = eth1DataTerm))
                    , 'ETH1_DEPOSIT_INDEX_CELL'            : (['eth1_deposit_index']                 , intToken)
                    , 'VALIDATORS_CELL'                    : (['validators']                         , indexedMapOf(converter = validatorTerm))
                    , 'BALANCES_CELL'                      : (['balances']                           , indexedMapOf(converter = intToken))
                    , 'RANDAO_MIXES_CELL'                  : (['randao_mixes']                       , bytesListTerm)
                    , 'SLASHINGS_CELL'                     : (['slashings']                          , indexedMapOf(converter = intToken))
                    , 'PREVIOUS_EPOCH_ATTESTATIONS_CELL'    : (['previous_epoch_attestations']       , listOf('PendingAttestation', converter = pendingAttestationTerm))
                    , 'CURRENT_EPOCH_ATTESTATIONS_CELL'    : (['current_epoch_attestations']         , listOf('PendingAttestation', converter = pendingAttestationTerm))
                      # justification_bits: Bitvector[JUSTIFICATION_BITS_LENGTH]
                    , 'JUSTIFICATION_BITS_CELL'            : (['justification_bits']                 , bitVectorTerm(JUSTIFICATION_BITS_LENGTH))
                    , 'PREVIOUS_JUSTIFIED_CHECKPOINT_CELL' : (['previous_justified_checkpoint']      , checkpointTerm)
                    , 'CURRENT_JUSTIFIED_CHECKPOINT_CELL'  : (['current_justified_checkpoint']       , checkpointTerm)
                    , 'FINALIZED_CHECKPOINT_CELL'          : (['finalized_checkpoint']               , checkpointTerm)
                    }

skip_keys = [
            #  'GENESIS_TIME_CELL'
            # , 'SLOT_CELL'
            # , 'FORK_CELL'
            # , 'LATEST_BLOCK_HEADER_CELL'
            # , 'BLOCK_ROOTS_CELL'
            # , 'STATE_ROOTS_CELL'
            # , 'HISTORICAL_ROOTS_CELL'
            # , 'ETH1_DATA_CELL'
            # , 'ETH1_DATA_VOTES_CELL'
            # , 'ETH1_DEPOSIT_INDEX_CELL'
            # , 'VALIDATORS_CELL'
            # , 'BALANCES_CELL'
            # , 'START_SHARD_CELL'
            # , 'RANDAO_MIXES_CELL'
            # , 'SLASHINGS_CELL'
            # , 'PREVIOUS_EPOCH_ATTESTATIONS_CELL'
            # , 'CURRENT_EPOCH_ATTESTATIONS_CELL'
            # , 'JUSTIFICATION_BITS_CELL'
            # , 'PREVIOUS_JUSTIFIED_CHECKPOINT_CELL'
            # , 'CURRENT_JUSTIFIED_CHECKPOINT_CELL'
            # , 'FINALIZED_CHECKPOINT_CELL'
            # , 'BLOCKSLOT_CELL'
            # , 'PARENT_ROOT_CELL'
            # , 'STATE_ROOT_CELL'
            # , 'SIGNATURE_CELL'
]

debug_keys = []

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

def coversKeyChain(used_chains, chain):
    for used_chain in used_chains:
        if len(used_chain) > len(chain):
            continue
        if all(chain[index] == val for index, val in enumerate(used_chain)):
            return True
    return False

def buildConfigSubstitution(test_pre_state, config_cells, skip_keys = [], debug_keys = []):
    new_key_table = {}
    used_key_chains = []
    for cell_var in config_cells:
        if cell_var not in skip_keys:
            (pre_keys, converter) = config_cells[cell_var]
            test_field = getKeyChain(test_pre_state, pre_keys)
            if test_field is None:
                _warning('Key not found: ' + str(pre_keys))
            else:
                kast_term = converter(getKeyChain(test_pre_state, pre_keys))
                if cell_var in debug_keys:
                    _notif(cell_var)
                    printerr(str(kast_term))
                    printerr(prettyPrintKast(kast_term, BEACON_CHAIN_symbols))
                new_key_table[cell_var] = kast_term
                used_key_chains.append(pre_keys)
        else:
            _warning('Unset configuration variable: ' + cell_var)
    for yaml_chain in gatherKeyChains(test_pre_state):
        if not coversKeyChain(used_key_chains, yaml_chain):
            _warning('Unused yaml key: ' + str(yaml_chain))

    return new_key_table

def loadYamlFileList(test_dir, base_name):
    blocks = []
    i = 0
    block = loadYaml(test_dir, '%s_%d.yaml' % (base_name, i))
    while block is not None:
        blocks.append(block)
        i += 1
        block = loadYaml(test_dir, '%s_%d.yaml' % (base_name, i))
    return blocks

def loadYaml(test_dir, name):
    try:
        post_file = Path.joinpath(test_dir, name).as_posix()
        result = yaml.load(open(post_file, 'r'), Loader = yaml.FullLoader)
        print("\n%s file: %s\n" % (name, post_file), flush=True)
        return result
    except FileNotFoundError:
        return None


def kast_diff(kast1, kast2, kast1Caption, kast2Caption, allow_diff = True):
    if kast1 != kast2:
        header = 'WARNING' if allow_diff else 'ERROR'
        _notif('[%s] %s and %s differ!' % (header, kast1Caption, kast2Caption))
        for line in difflib.unified_diff(kast1.split('\n'), kast2.split('\n'), fromfile=kast1Caption,
                                         tofile=kast2Caption, lineterm='\n'):
            sys.stderr.write(line + '\n')
        sys.stderr.flush()
        if not allow_diff:
            sys.exit(3)

def buildPreConfigSubst(test_dir):
    test_runner = test_dir.parts[-4]
    test_handler = test_dir.parts[-3]
    file_name = 'value.yaml' if test_runner == 'ssz_static' and test_handler == 'BeaconState' \
        else 'genesis.yaml' if test_runner == 'genesis' and test_handler == 'validity' \
        else 'pre.yaml'
    pre_yaml = loadYaml(test_dir, file_name)
    if pre_yaml is not None:
        return buildConfigSubstitution(pre_yaml, init_config_cells, skip_keys=skip_keys, debug_keys=debug_keys)
    else:
        return {}

def buildKCell(test_dir):
    test_runner = test_dir.parts[-4]
    test_handler = test_dir.parts[-3]
    if test_runner == 'ssz_static':
        if test_handler == 'BeaconState':
            entry_point = 'wrap_hash_tree_root_state'
        else:
            entry_point = 'wrap_hash_tree_root'
        arg_converter = data_class_to_converter[test_handler]
        file_name = 'value.yaml'
    elif test_runner == 'sanity' and test_handler == 'blocks':
        blocks = loadYamlFileList(test_dir, 'blocks')
        resultSeq = [KApply('init', [])] \
                    + [KApply('state_transition', [signedBeaconBlockTerm(block), boolToken('true')]) for block in blocks]
        return KSequence(resultSeq)
    elif test_runner == 'genesis' and test_handler == 'initialization':
        eth1_block_hash = loadYaml(test_dir, 'eth1_block_hash.yaml')
        eth1_timestamp = loadYaml(test_dir, 'eth1_timestamp.yaml')
        deposits = loadYamlFileList(test_dir, 'deposits')
        return KSequence([
            KApply('init', []),
            KApply('initialize_beacon_state_from_eth1',
                   [hashToken(eth1_block_hash), intToken(eth1_timestamp),
                    listOf('Deposit', converter = depositTerm)(deposits)])
            ])
    elif test_runner in ('operations', 'epoch_processing', 'sanity', 'genesis'):
        if test_handler not in test_type_to_term.keys():
            raise Exception("Unsupported test handler: " + test_handler)
        if test_handler == 'slots':
            entry_point = 'test_process_%s' % test_handler
        elif test_handler == 'validity':
            entry_point = 'wrap_is_valid_genesis_state'
        else:
            entry_point = 'process_%s' % test_handler
        arg_converter = test_type_to_term[test_handler]
        if test_handler == 'block_header':
            file_name = "block.yaml"
        else:
            file_name = "%s.yaml" % test_handler
    else:
        raise Exception("Unsupported test runner: " + test_runner)

    return KSequence([
        KApply('init', []),
        KApply(entry_point,
               [arg_converter(loadYaml(test_dir, file_name))] if arg_converter is not None else [])
        ])

def buildPostKCell(test_dir):
    test_runner = test_dir.parts[-4]
    test_handler = test_dir.parts[-3]
    if test_runner == 'ssz_static':
        return KSequence([
                KApply('init', []),
                hashToken(loadYaml(test_dir, 'roots.yaml')['root'])
               ])
    elif test_handler == 'validity':
        return KSequence([
                KApply('init', []),
                boolToken(loadYaml(test_dir, 'is_valid.yaml'))
               ])
    else:
        return None

def getPostFile(test_dir):
    test_runner = test_dir.parts[-4]
    test_handler = test_dir.parts[-3]
    if test_runner == 'genesis' and test_handler == 'initialization':
        return 'state.yaml'
    else:
        return 'post.yaml'

def main():
    arguments = argparse.ArgumentParser(prog = sys.argv[0])
    arguments.add_argument('command'        , choices = ['parse'])
    arguments.add_argument('-o', '--output' , type = argparse.FileType('w'), default = '-')
    arguments.add_argument('--test'         , type = argparse.FileType('r'), default = '-')
    arguments.add_argument('--allow-diff'   , dest='allow_diff', action='store_true')
    arguments.add_argument('-d', '--debug'  , dest='debug', action='store_true')
    arguments.add_argument('-b', '--backend')

    args = arguments.parse_args()

    test_dir = Path(args.test.name).parent
    test_title = str(test_dir)
    _notif(test_title)

    (generated_top_config, init_subst) = get_init_config(args.backend)

    init_config_subst = copy.deepcopy(init_subst)
    all_keys = list(init_subst.keys())

    init_config_subst.update(buildPreConfigSubst(test_dir))             # build state
    init_config_subst['K_CELL'] = buildKCell(test_dir)                  # build <k>

    init_config = substitute(generated_top_config, init_config_subst)
    kast_json = { 'format' : 'KAST' , 'version' : 1.0 , 'term' : init_config }

    with tempfile.NamedTemporaryFile(mode = 'w', delete = not args.debug) as pre_json_file:
        json.dump(kast_json, pre_json_file)
        pre_json_file.flush()

        fastPrinted = prettyPrintKast(init_config['args'][0], beacon_chain_symbols(args.backend)).strip()
        _notif('kast content')
        print(fastPrinted, file = sys.stderr, flush = True)

        kastPrinted = fastPrinted
        # ISSUE: kast does not work with KSequence of 2 elements in <k>.
        # (returnCode, kastPrinted, _) = kast(pre_json_file.name, '--input', 'json', '--output', 'pretty', '--debug')
        # if returnCode != 0:
        #     _fatal('kast returned non-zero exit code: ' + test_title, code = returnCode)

        kastPrinted = kastPrinted.strip()
        kast_diff(kastPrinted, fastPrinted, 'kastPrinted', 'fastPrinted')

        krun_args = [pre_json_file.name, args.backend, '--term', '--parser', 'cat']
        if args.debug:
            krun_args.append('--debug')
        (returnCode, krunPrinted, _) = krun(*krun_args)
        krunPrinted = krunPrinted.strip()

    meta_yaml = loadYaml(test_dir, "meta.yaml")
    if meta_yaml is not None and 'bls_setting' in meta_yaml and meta_yaml['bls_setting'] == 1:
        _warning('`bls_setting` enabled: skipping post-state verification')
        return

    # Printing the post state
    post_yaml = loadYaml(test_dir, getPostFile(test_dir))
    post_k_cell = buildPostKCell(test_dir)
    if post_yaml is not None or post_k_cell is not None:
        if returnCode != 0:
            _fatal('krun returned non-zero exit code for positive test: ' + test_title, code = returnCode)

        post_config_subst = copy.deepcopy(init_config_subst)
        if post_yaml is not None:
            post_config_subst.update(buildConfigSubstitution(post_yaml, init_config_cells,
                                                             skip_keys=skip_keys, debug_keys=debug_keys))
        post_config_subst['K_CELL'] = post_k_cell if post_k_cell is not None else KConstant('init')

        post_config = substitute(generated_top_config, post_config_subst)
        post_kast_json = { 'format' : 'KAST' , 'version' : 1.0 , 'term' : post_config }
        with tempfile.NamedTemporaryFile(mode = 'w', delete = not args.debug) as post_json_file:
            json.dump(post_kast_json, post_json_file)
            post_json_file.flush()

            # (returnCode, postKastPrinted, _) = kast(post_json_file.name, '--input', 'json', '--output', 'pretty', '--debug')
            # Using krun to get same string encoding as for main krun
            (returnCode, postKastPrinted, _) = krun(post_json_file.name, args.backend, '--term', '--parser', 'cat')
            postKastPrinted = postKastPrinted.strip()
            if returnCode != 0:
                _fatal('kast returned non-zero exit code: ' + test_title, code = returnCode)

            kast_diff(krunPrinted, postKastPrinted, 'krun_out', 'expected_post_state', args.allow_diff)
    else: # negative tests
        if returnCode != 0:
            print('\nNegative test passed. Exit code: %d' % returnCode, flush=True)
        else:
            empty_k_match = re.search(re.compile('<k>\\s*\\.\\s*</k>'), krunPrinted)
            if empty_k_match is None:
                print('\nNegative test passed. Non-empty <k>', flush=True)
            else:
                _fatal('\nkrun returned zero exit code and empty <k> for negative test')

if __name__ == '__main__':
    main()
