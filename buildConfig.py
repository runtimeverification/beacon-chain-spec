#!/usr/bin/env python3

import json
import sys
import tempfile

from functools import reduce

import pyk

from pyk.kast      import combineDicts, appliedLabelStr, constLabel, underbarUnparsing, K_symbols, KApply, KConstant, KSequence, KVariable, KToken
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

def assocSort(elemSort):
    if elemSort == 'Hash':
        elemSort = "Bytes"
    return '_TYPES__' + elemSort + '_' + listSort(elemSort)


def listSort(elemSort):
    if elemSort == 'Hash':
        return 'BytesList'
    return elemSort + 'List'


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

def kast(inputFile, *kastArgs):
    return pyk.kast('.build/defn/llvm', inputFile, kastArgs = list(kastArgs), kRelease = 'deps/k/k-distribution/target/release/k')

def krun(inputFile, *krunArgs):
    return pyk.krun('.build/defn/llvm', inputFile, krunArgs = list(krunArgs), kRelease = 'deps/k/k-distribution/target/release/k')

BEACON_CHAIN_symbols = { '.ProposerSlashingCellMap' : constLabel('.ProposerSlashingCellMap') }

TYPES_constLabels = [ '.Eth1Data'
                    , '.Fork'
                    , '.Checkpoint'
                    , '.BlockHeader'
                    ]

for cLabel in TYPES_constLabels:
    BEACON_CHAIN_symbols[cLabel + '_TYPES_'] = constLabel(cLabel)

TYPES_appliedLabels = [ '#Fork'
                      , '#Validator'
                      , '#Crosslink'
                      , '#BeaconBlockHeader'
                      , '#Eth1Data'
                      , '#AttestationData'
                      , '#PendingAttestation'
                      , '#Transfer'
                      ]

for appliedLabel in TYPES_appliedLabels:
    BEACON_CHAIN_symbols[appliedLabel] = appliedLabelStr(appliedLabel)

BEACON_CHAIN_lists = [ 'PendingAttestation'
                     , 'AttesterSlashing'
                     , 'Attestation'
                     , 'Deposit'
                     , 'VoluntaryExit'
                     , 'Transfer'
                     , 'Bytes32'
                     , 'Uint64'
                     , 'Eth1Data'
                     , 'Crosslink'
                     , 'Hash'
                     , 'Bit'
                     , 'Transfer'
                     ]

for list_sort in BEACON_CHAIN_lists:
    BEACON_CHAIN_symbols[assocUnit(list_sort)] = constLabel('.' + listSort(list_sort))
    BEACON_CHAIN_symbols[assocJoin(list_sort)] = lambda e, es: e + '  ' + es

ALL_symbols = combineDicts(K_symbols, BEACON_CHAIN_symbols)

# Read in the symbolic configuration
# configuration = readKastTerm(sys.argv[1])

def krunJson(inputJson, *krunArgs):
    return pyk.krunJSON('.build/defn/llvm', inputJson, krunArgs = list(krunArgs), kRelease = 'deps/k/k-distribution/target/release/k')

def get_init_config():
    init_term = { 'format': 'KAST', 'version': 1, 'term': KConstant('noop') }
    (_, simple_config, _) = krunJson(init_term)
    return pyk.splitConfigFrom(simple_config)

(generated_top_config, init_subst) = get_init_config()
initial_configuration = substitute(generated_top_config, init_subst)

if __name__ == '__main__':
    kast_json = { 'format': 'KAST', 'version': 1, 'term': initial_configuration }
    with tempfile.NamedTemporaryFile(mode = 'w') as tempf:
        json.dump(kast_json, tempf)
        tempf.flush()
        (returnCode, _, _) = kast(tempf.name, '--input', 'json', '--output', 'pretty')
        if returnCode != 0:
            printerr('[FATAL] kast returned non-zero exit code reading/printing the initial configuration')
            sys.exit(returnCode)
