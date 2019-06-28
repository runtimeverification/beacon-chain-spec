#!/usr/bin/env python3

import sys
import yaml

import buildConfig

if __name__ == "__main__":
    test_file = sys.argv[1]

    with open(test_file, "r") as yaml_file:
        yaml_test = yaml.load(yaml_file, Loader = yaml.FullLoader)

    print(yaml_test['title'])
