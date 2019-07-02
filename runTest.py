#!/usr/bin/env python3

import sys
import yaml

from buildConfig import *

intToken = lambda x: KToken(str(x), 'Int')

pre_keys = { "slot"                        : ('SLOT_CELL'         , intToken)
           , "genesis_time"                : ('GENESIS_TIME_CELL' , intToken)
           # , "fork"                        : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "validator_registry"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "balances"                    : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_randao_mixes"         : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_start_shard"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "previous_epoch_attestations" : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "current_epoch_attestations"  : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "previous_justified_epoch"    : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "current_justified_epoch"     : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "previous_justified_root"     : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "current_justified_root"      : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "justification_bitfield"      : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "finalized_epoch"             : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "finalized_root"              : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "current_crosslinks"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "previous_crosslinks"         : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_block_roots"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_state_roots"          : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_active_index_roots"   : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_slashed_balances"     : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_block_header"         : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "historical_roots"            : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "latest_eth1_data"            : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "eth1_data_votes"             : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
           # , "deposit_index"               : ('NOT_IMPLEMENTED' , lambda x: KVariable('NOT_IMPLEMENTED'))
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
        if pre_key in pre_keys:
            (cell_var, converter) = pre_keys[pre_key]
            keytable[cell_var] = converter(test_case['pre'][pre_key])
        else:
            print("unused pre-key: " + pre_key)

    if test_case['post'] is None:
        print("No post condition!")
    else:
        print("post keys: " + str(test_case['post'].keys()))

    init_config = substitute(symbolic_configuration, keytable)
    print(prettyPrintKast(init_config, ALL_symbols))
