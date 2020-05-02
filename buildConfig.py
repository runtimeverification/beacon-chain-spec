#!/usr/bin/env python3

import json
import sys
import tempfile
import argparse

from functools import reduce

import pyk

from pyk.kast      import combineDicts, appliedLabelStr, constLabel, underbarUnparsing, KApply, KConstant, KSequence, KVariable, KToken
from pyk.kastManip import substitute, prettyPrintKast

def printerr(msg):
    sys.stderr.write(msg + '\n')

intToken    = lambda x: KToken(str(x), 'Int')
boolToken   = lambda x: KToken(str(x).lower(), 'Bool')
intToBoolToken = lambda x: KToken("true" if x == '1' else "false", 'Bool')
boolToBoolStringToken = lambda x: KToken("true" if x else "false", 'Bool')
stringToken = lambda x: KToken('"' + str(x) + '"', 'String')
hashToken = lambda x: KToken('"' + "".join("\\x" + str(x)[i:i+2] for i in range(2, len(str(x)), 2)) + '"', 'String')

hexIntToken = lambda x: intToken(int(x, 16))

unimplemented = lambda input: KToken('UNIMPLEMENTED << ' + str(input) + ' >>', 'K')

foldr = lambda func, init: lambda xs: reduce(lambda x, y: func(y, x), xs[::-1], init)

def listSort(elemSort):
    if elemSort == 'Hash':
        return 'BytesList'
    return elemSort + 'List'

def assocSort(elemSort):
    if elemSort == 'Hash':
        elemSort = "Bytes"
    return '_TYPES_' + listSort(elemSort) + '_' + elemSort + '_' + listSort(elemSort)

def assocJoin(elemSort):
    return '__' + assocSort(elemSort)

def assocUnit(elemSort):
    return '.List{"' + assocJoin(elemSort) + '"}_' + listSort(elemSort)

def assocWithUnitAST(joinKLabel, emptyKLabel, converter = lambda x: x):
    emptyElem = KApply(emptyKLabel, [])
    _join = lambda head, tail: KApply(joinKLabel, [converter(head), tail])
    return foldr(_join, KApply(emptyKLabel, []))

def indexedMapOf(converter = lambda x: x):
    def _indexedMapOf(inputList):
        mapElements = [ KApply('_|->_', [intToken(k), converter(v)]) for (k,v) in enumerate(inputList) ]
        return assocWithUnitAST('_Map_', '.Map')(mapElements)
    return _indexedMapOf

def listOf(sort, converter = lambda x: x):
    lJoin = '__' + assocSort(sort)
    lUnit = assocUnit(sort)
    return assocWithUnitAST(lJoin, lUnit, converter = converter)

def labelWithKeyPairs(label, keyConverters):
    def _labelWithKeyPairs(input):
        args = [ converter(input[key]) for (key, converter) in keyConverters ]
        return KApply(label, args)
    return _labelWithKeyPairs

def beacon_chain_symbols(backend):
    BEACON_CHAIN_definition = pyk.readKastTerm('.build/defn/%s/beacon-chain-kompiled/compiled.json' % backend)
    return pyk.buildSymbolTable(BEACON_CHAIN_definition)

def kast(inputFile, backend, *kastArgs):
    return pyk.kast('.build/defn/%s' % backend, inputFile, kastArgs = list(kastArgs))

def krun(inputFile, backend, *krunArgs):
    return pyk.krun('.build/defn/%s' % backend, inputFile, krunArgs = list(krunArgs))

def krunJson(inputJson, backend, *krunArgs):
    return pyk.krunJSON('.build/defn/%s' % backend, inputJson, krunArgs = list(krunArgs))

def get_init_config(backend):
    init_term = { 'format': 'KAST', 'version': 1, 'term': KConstant('noop') }
    (_, simple_config, _) = krunJson(init_term, backend)
    return pyk.splitConfigFrom(simple_config)


if __name__ == '__main__':
    arguments = argparse.ArgumentParser(prog = sys.argv[0])
    arguments.add_argument('-b', '--backend')
    args = arguments.parse_args()

    (generated_top_config, init_subst) = get_init_config(args.backend)
    initial_configuration = substitute(generated_top_config, init_subst)
    kast_json = { 'format': 'KAST', 'version': 1, 'term': initial_configuration }
    with tempfile.NamedTemporaryFile(mode = 'w') as tempf:
        json.dump(kast_json, tempf)
        tempf.flush()
        (returnCode, _, _) = kast(tempf.name, args.backend, '--input', 'json', '--output', 'pretty')
        if returnCode != 0:
            printerr('[FATAL] kast returned non-zero exit code reading/printing the initial configuration')
            sys.exit(returnCode)
