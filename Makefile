# Settings
# --------

BUILD_DIR   := .build
DEFN_DIR    := $(BUILD_DIR)/defn
BUILD_LOCAL := $(CURDIR)/$(BUILD_DIR)/local
LOCAL_LIB   := $(BUILD_LOCAL)/lib

LIBRARY_PATH    := $(LOCAL_LIB)
INCLUDE_PATH    := $(BUILD_LOCAL)/include
PKG_CONFIG_PATH := $(LIBRARY_PATH)/pkgconfig

export LIBRARY_PATH
export INCLUDE_PATH
export PKG_CONFIG_PATH

DEPS_DIR         := deps
K_SUBMODULE      := $(abspath $(DEPS_DIR)/k)
PLUGIN_SUBMODULE := $(abspath $(DEPS_DIR)/plugin)

ifneq (,$(wildcard $(K_SUBMODULE)/k-distribution/target/release/k/bin/*))
    K_RELEASE ?= $(abspath $(K_SUBMODULE)/k-distribution/target/release/k)
else
    K_RELEASE ?= $(dir $(shell which kompile))..
endif
K_BIN := $(K_RELEASE)/bin
K_LIB := $(K_RELEASE)/lib/kframework
export K_RELEASE

PATH := $(K_BIN):$(PATH)
export PATH

PYTHONPATH := $(K_LIB):/usr/lib/kframework/lib
export PYTHONPATH

TEST_DIR             := tests
ETH2_TESTS_SUBMODULE := $(TEST_DIR)/eth2.0-spec-tests

.PHONY: all clean                                        \
        libff libsecp256k1                               \
        deps deps-k deps-plugin deps-tests               \
        defn defn-llvm defn-haskell                      \
        build build-llvm build-llvm-bounds build-haskell \
        test test-split test-python-config test-processing test-ssz
.SECONDARY:

all: build

clean:
	rm -rf $(BUILD_DIR)

clean-submodules:
	rm -rf $(DEPS_DIR)/k/submodule.timestamp $(DEPS_DIR)/k/mvn.timestamp tests/eth2.0-specs/submodule.timestamp
	cd $(DEPS_DIR)/k         && mvn clean --quiet
	cd $(DEPS_DIR)/secp256k1 && make distclean || true

# Non-K Dependencies
# ------------------

libsecp256k1_out:=$(LOCAL_LIB)/pkgconfig/libsecp256k1.pc
libff_out:=$(LOCAL_LIB)/libff.a

libsecp256k1: $(libsecp256k1_out)
libff: $(libff_out)

$(DEPS_DIR)/secp256k1/autogen.sh:
	git submodule update --init --recursive -- $(DEPS_DIR)/secp256k1

$(libsecp256k1_out): $(DEPS_DIR)/secp256k1/autogen.sh
	cd $(DEPS_DIR)/secp256k1/ \
	    && ./autogen.sh \
	    && ./configure --enable-module-recovery --prefix="$(BUILD_LOCAL)" \
	    && make -s -j4 \
	    && make install

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
    LIBFF_CMAKE_FLAGS=
else
    LIBFF_CMAKE_FLAGS=-DWITH_PROCPS=OFF
endif

LIBFF_CC ?=clang-8
LIBFF_CXX?=clang++-8

$(DEPS_DIR)/libff/CMakeLists.txt:
	git submodule update --init --recursive -- $(DEPS_DIR)/libff

$(libff_out): $(DEPS_DIR)/libff/CMakeLists.txt
	cd $(DEPS_DIR)/libff/ \
	    && mkdir -p build \
	    && cd build \
	    && CC=$(LIBFF_CC) CXX=$(LIBFF_CXX) cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$(BUILD_LOCAL) $(LIBFF_CMAKE_FLAGS) \
	    && make -s -j4 \
	    && make install

# Dependencies
# ------------

deps: deps-k deps-tests deps-plugin
deps-k:      $(K_SUBMODULE)/mvn.timestamp
deps-tests:  $(ETH2_TESTS_SUBMODULE)/submodule.timestamp
deps-plugin: $(PLUGIN_SUBMODULE)/make.timestamp

%/submodule.timestamp:
	git submodule update --init --recursive -- $*
	touch $@

$(K_SUBMODULE)/mvn.timestamp: $(K_SUBMODULE)/submodule.timestamp
	cd $(K_SUBMODULE) && mvn package -DskipTests
	touch $(K_SUBMODULE)/mvn.timestamp

$(PLUGIN_SUBMODULE)/make.timestamp:
	git submodule update --init --recursive -- $(PLUGIN_SUBMODULE)
	touch $(PLUGIN_SUBMODULE)/make.timestamp

# Building
# --------

MAIN_MODULE    := BEACON-CHAIN
SYNTAX_MODULE  := $(MAIN_MODULE)
MAIN_DEFN_FILE := beacon-chain

# Generate definitions from source files

k_files := $(MAIN_DEFN_FILE).k hash-tree.k types.k config.k constants-minimal.k uint64.k

bounds_files := $(MAIN_DEFN_FILE).k hash-tree.k types.k config.k uint64.k constants-minimal.k

llvm_dir_minimal  := $(DEFN_DIR)/llvm-minimal
llvm_dir_bounds   := $(DEFN_DIR)/llvm-bounds
llvm_files        := $(patsubst %,$(llvm_dir_minimal)/%,$(k_files))
llvm_bounds_files := $(patsubst %,$(llvm_dir_bounds)/%,$(bounds_files))

haskell_dir   := $(DEFN_DIR)/haskell
haskell_files := $(patsubst %,$(haskell_dir)/%,$(k_files))

defn: llvm-defn haskell-defn
defn-llvm:    $(llvm_files)
defn-haskell: $(haskell_files)

$(llvm_dir_minimal)/%.k: %.k
	@mkdir -p $(llvm_dir_minimal)
	cp $< $@

$(llvm_dir_bounds)/constants-minimal.k: constants-bounds-check.k
	@mkdir -p $(llvm_dir_bounds)
	cp $< $@

$(llvm_dir_bounds)/%.k: %.k
	@mkdir -p $(llvm_dir_bounds)
	cp $< $@

$(haskell_dir)/%.k: %.k
	@mkdir -p $(haskell_dir)
	cp $< $@

# Building

KOMPILE_OPTS ?=

LLVM_KOMPILE_OPTS := -I$(K_RELEASE)/include/kllvm -I$(INCLUDE_PATH) -L$(LOCAL_LIB) \
                     -lff -lcryptopp -lsecp256k1                                   \
                     $(PLUGIN_SUBMODULE)/plugin-c/crypto.cpp                       \
                     -g

ifeq ($(UNAME_S),Linux)
    LLVM_KOMPILE_OPTS += -lprocps
endif

llvm_kompiled        := $(llvm_dir_minimal)/$(MAIN_DEFN_FILE)-kompiled/interpreter
llvm_kompiled_bounds := $(llvm_dir_bounds)/$(MAIN_DEFN_FILE)-kompiled/interpreter
haskell_kompiled     := $(haskell_dir)/$(MAIN_DEFN_FILE)-kompiled/definition.kore

build: build-llvm build-haskell build-llvm-bounds
build-llvm:        $(llvm_kompiled)
build-llvm-bounds: $(llvm_kompiled_bounds)
build-haskell:     $(haskell_kompiled)

# LLVM Backend (configuration: minimal)

$(llvm_kompiled): $(llvm_files) $(libff_out)
	kompile --debug --main-module $(MAIN_MODULE) --backend llvm                      \
	        --syntax-module $(SYNTAX_MODULE) $(llvm_dir_minimal)/$(MAIN_DEFN_FILE).k \
	        --directory $(llvm_dir_minimal) -I $(llvm_dir_minimal)                   \
	        --hook-namespaces KRYPTO                                                 \
	        --emit-json                                                              \
	        $(KOMPILE_OPTS) $(addprefix -ccopt ,$(LLVM_KOMPILE_OPTS))

# LLVM Backend (configuration: bounds-check)

$(llvm_kompiled_bounds): $(llvm_bounds_files) $(libff_out)
	kompile --debug --main-module $(MAIN_MODULE) --backend llvm                     \
	        --syntax-module $(SYNTAX_MODULE) $(llvm_dir_bounds)/$(MAIN_DEFN_FILE).k \
	        --directory $(llvm_dir_bounds) -I $(llvm_dir_bounds)                    \
	        --hook-namespaces KRYPTO                                                \
	        --emit-json                                                             \
	        $(KOMPILE_OPTS) $(addprefix -ccopt ,$(LLVM_KOMPILE_OPTS))

# Haskell Backend

$(haskell_kompiled): $(haskell_files)
	kompile --debug --main-module $(MAIN_MODULE) --backend haskell              \
	        --syntax-module $(SYNTAX_MODULE) $(haskell_dir)/$(MAIN_DEFN_FILE).k \
	        --directory $(haskell_dir) -I $(haskell_dir)                        \
	        --hook-namespaces KRYPTO                                            \
	        --emit-json

# Testing
# -------

test-split:
	cd $(ETH2_TESTS_SUBMODULE) \
	    && git lfs install     \
	    && git lfs fetch       \
	    && git lfs checkout

operations_tests:=$(wildcard tests/eth2.0-spec-tests/tests/minimal/phase0/operations/*/*/*/pre.yaml)
epoch_processing_tests:=$(wildcard tests/eth2.0-spec-tests/tests/minimal/phase0/epoch_processing/*/*/*/pre.yaml)
sanity_tests:=$(wildcard tests/eth2.0-spec-tests/tests/minimal/phase0/sanity/*/*/*/pre.yaml)
genesis_tests:=$(wildcard tests/eth2.0-spec-tests/tests/minimal/phase0/genesis/initialization/*/*/state.yaml) \
               $(wildcard tests/eth2.0-spec-tests/tests/minimal/phase0/genesis/validity/*/*/genesis.yaml)

ssz_tests = $(wildcard tests/eth2.0-spec-tests/tests/minimal/phase0/ssz_static/*/*/case_0/value.yaml)
all_process_tests:= $(operations_tests) $(epoch_processing_tests) $(sanity_tests) $(genesis_tests)
all_tests = $(all_process_tests) $(ssz_tests)

# Testing on LLVM Backend

test: test-llvm test-bounds

test-llvm: test-python-config-llvm test-all-llvm

test-bounds: test-python-config-llvm-bounds test-epoch-processing-bounds

test-python-config-llvm-bounds: $(llvm_kompiled_bounds)
	python3 buildConfig.py -b llvm-bounds

test-python-config-llvm: $(llvm_kompiled)
	python3 buildConfig.py -b llvm-minimal

test-processing: $(all_process_tests:=.test)

test-ssz: $(ssz_tests:=.test)

test-all-llvm: $(all_tests:=.test)

%.yaml.bounds-test: %.yaml $(llvm_kompiled_bounds)
	python3 runTest.py parse -b llvm-bounds --test $*.yaml

%.yaml.bounds-test-allow-diff: %.yaml $(llvm_kompiled_bounds)
	python3 runTest.py parse -b llvm-bounds --test $*.yaml --allow-diff

# Same as above, but invokes krun with --debug and does not halt when diff vs expected state is detected
%.yaml.bounds-test-debug: %.yaml $(llvm_kompiled_bounds)
	python3 runTest.py parse -b llvm-bounds --test $*.yaml --debug --allow-diff

test-epoch-processing-bounds: tests/eth2.0-spec-tests/tests/minimal/phase0/epoch_processing/rewards_and_penalties/pyspec_tests/attestations_some_slashed/pre.yaml.bounds-test

%.yaml.test: %.yaml $(llvm_kompiled)
	python3 runTest.py parse -b llvm-minimal --test $*.yaml

%.yaml.test-allow-diff: %.yaml $(llvm_kompiled)
	python3 runTest.py parse -b llvm-minimal --test $*.yaml --allow-diff

# Same as above, but invokes krun with --debug and does not halt when diff vs expected state is detected
%.yaml.test-debug: %.yaml $(llvm_kompiled)
	python3 runTest.py parse -b llvm-minimal --test $*.yaml --debug --allow-diff

# Testing on Haskell Backend

test-haskell: test-python-config-haskell test-all-haskell

test-python-config-haskell: $(haskell_kompiled)
	python3 buildConfig.py -b haskell

test-all-haskell: $(all_tests:=.test-haskell)

%.yaml.test-haskell: %.yaml $(haskell_kompiled)
	python3 runTest.py parse -b haskell --test $*.yaml

%.yaml.test-haskell-debug: %.yaml $(haskell_kompiled)
	python3 runTest.py parse -b haskell --test $*.yaml --debug --allow-diff

# Sphinx HTML Documentation

# You can set these variables from the command line.
SPHINXOPTS     =
SPHINXBUILD    = sphinx-build
PAPER          =
SPHINXBUILDDIR = $(BUILD_DIR)/sphinx-docs

# Internal variables.
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
ALLSPHINXOPTS   = -d ../$(SPHINXBUILDDIR)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .
# the i18n builder cannot share the environment and doctrees with the others
I18NSPHINXOPTS  = $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .

sphinx:
	mkdir -p $(SPHINXBUILDDIR) \
	    && cp -r media/sphinx-docs/* $(SPHINXBUILDDIR) \
	    && cp -r *.md $(SPHINXBUILDDIR)/. \
	    && cp -r *.k $(SPHINXBUILDDIR)/. \
	    && cd $(SPHINXBUILDDIR) \
	    && ./k-to-md.sh \
	    && $(SPHINXBUILD) -b dirhtml $(ALLSPHINXOPTS) html \
	    && $(SPHINXBUILD) -b text $(ALLSPHINXOPTS) html/text
