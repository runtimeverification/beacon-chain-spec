#!/usr/bin/env python3

import sys
import yaml

from buildConfig import *

pre_keys = { "slot" : ('SLOT_CELL', lambda x: KToken(str(x), "Int"))
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
