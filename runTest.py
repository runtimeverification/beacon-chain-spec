#!/usr/bin/env python3

import sys
import yaml

from buildConfig import *

intToken = lambda x: KToken(str(x), 'Int')

def consList(join, empty = ""):
    def _consList(input):
        if len(input) == 0:
            return KToken(empty, "K")
        else:
            return KToken(str(input), "NOT_IMPLEMENTED")
    return _consList

pre_keys = { "slot"                        : ('SLOT_CELL'         , intToken)
           , "genesis_time"                : ('GENESIS_TIME_CELL' , intToken)
           # , "fork"                        : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "validator_registry"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "balances"                    : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_randao_mixes"         : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           , "latest_start_shard"          : ('LATEST_START_SHARD_CELL' , intToken)
           , "previous_epoch_attestations" : ('PREVIOUS_EPOCH_ATTESTATION_CELL' , consList('???'))
           , "current_epoch_attestations"  : ('CURRENT_EPOCH_ATTESTATIONS_CELL' , consList('???'))
           , "previous_justified_epoch"    : ('PREVIOUS_JUSTIFIED_EPOCH_CELL' , intToken)
           , "current_justified_epoch"     : ('CURRENT_JUSTIFIED_EPOCH_CELL' , intToken)
           # , "previous_justified_root"     : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "current_justified_root"      : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           , "justification_bitfield"      : ('JUSTIFICATION_BITFIELD_CELL' , intToken)
           , "finalized_epoch"             : ('FINALIZED_EPOCH_CELL' , intToken)
           # , "finalized_root"              : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "current_crosslinks"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "previous_crosslinks"         : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_block_roots"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_state_roots"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_active_index_roots"   : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_slashed_balances"     : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_block_header"         : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           , "historical_roots"            : ('HISTORICAL_ROOTS_CELL' , consList('???'))
           # , "latest_eth1_data"            : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           , "eth1_data_votes"             : ('ETH1_DATA_VOTES_CELL' , consList('???'))
           , "deposit_index"               : ('DEPOSIT_INDEX_CELL' , intToken)
           }

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
                keytable[cell_var] = converter(test_pre)
            else:
                print("unimplemented pre-key: " + str(pre_key) + " -> " + str(test_pre))
        elif len(str(test_pre)) < 3:
            print("unused pre-key: " + pre_key)

    if test_case['post'] is None:
        print("No post condition!")
    else:
        print("post keys: " + str(test_case['post'].keys()))

    init_config = substitute(symbolic_configuration, keytable)
    print(prettyPrintKast(init_config, ALL_symbols))
