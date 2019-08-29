# Settings
# --------

BUILD_DIR:=.build
DEFN_DIR:=$(BUILD_DIR)/defn
BUILD_LOCAL:=$(CURDIR)/$(BUILD_DIR)/local
LIBRARY_PATH:=$(BUILD_LOCAL)/lib
INCLUDE_PATH:=$(BUILD_LOCAL)/include
PKG_CONFIG_PATH:=$(LIBRARY_PATH)/pkgconfig
export LIBRARY_PATH
export PKG_CONFIG_PATH

DEPS_DIR:=deps
K_SUBMODULE:=$(abspath $(DEPS_DIR)/k)
PANDOC_TANGLE_SUBMODULE:=$(DEPS_DIR)/pandoc-tangle
PLUGIN_SUBMODULE:=$(abspath $(DEPS_DIR)/plugin)

K_RELEASE:=$(K_SUBMODULE)/k-distribution/target/release/k
K_BIN:=$(K_RELEASE)/bin
K_LIB:=$(K_RELEASE)/lib

PATH:=$(K_BIN):$(PATH)
export PATH

PYTHONPATH:=$(K_LIB)
export PYTHONPATH

TANGLER:=$(PANDOC_TANGLE_SUBMODULE)/tangle.lua
LUA_PATH:=$(PANDOC_TANGLE_SUBMODULE)/?.lua;;
export TANGLER
export LUA_PATH

TEST_DIR:=tests
ETH2_TESTS_SUBMODULE:=$(TEST_DIR)/eth2.0-spec-tests

.PHONY: all clean \
        libff libsecp256k1 \
        deps deps-k deps-tangle deps-plugin deps-tests \
        defn defn-llvm defn-haskell \
        build build-llvm build-haskell \
        test test-split test-python-config test-operations-minimal
.SECONDARY:

all: build

clean:
	rm -rf $(BUILD_DIR)

clean-submodules:
	rm -rf $(DEPS_DIR)/k/submodule.timestamp $(DEPS_DIR)/k/mvn.timestamp $(DEPS_DIR)/pandoc-tangle/submodule.timestamp tests/eth2.0-specs/submodule.timestamp

# Non-K Dependencies
# ------------------

libsecp256k1_out:=$(LIBRARY_PATH)/pkgconfig/libsecp256k1.pc
libff_out:=$(LIBRARY_PATH)/libff.a

libsecp256k1: $(libsecp256k1_out)
libff: $(libff_out)

$(DEPS_DIR)/secp256k1/autogen.sh:
	@echo "== submodule: $(DEPS_DIR)/secp256k1"
	git submodule update --init --recursive -- $(DEPS_DIR)/secp256k1

$(PLUGIN_SUBMODULE)/make.timestamp:
	@echo "== submodule: $@"
	git submodule update --init --recursive -- $(PLUGIN_SUBMODULE)
	touch $(PLUGIN_SUBMODULE)/make.timestamp

$(libsecp256k1_out): $(DEPS_DIR)/secp256k1/autogen.sh
	cd $(DEPS_DIR)/secp256k1/ \
	    && ./autogen.sh \
	    && ./configure --enable-module-recovery --prefix="$(BUILD_LOCAL)" \
	    && make -s -j4 \
	    && make install

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)
  LIBFF_CMAKE_FLAGS=
  LINK_PROCPS=-lprocps
else
  LIBFF_CMAKE_FLAGS=-DWITH_PROCPS=OFF
  LINK_PROCPS=
endif

LIBFF_CC ?=clang-8
LIBFF_CXX?=clang++-8

$(DEPS_DIR)/libff/CMakeLists.txt:
	@echo "== submodule: $(DEPS_DIR)/libff"
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

deps: deps-k deps-tangle deps-tests deps-plugin
deps-k: $(K_SUBMODULE)/mvn.timestamp
deps-tangle: $(PANDOC_TANGLE_SUBMODULE)/submodule.timestamp
deps-tests: $(ETH2_TESTS_SUBMODULE)/submodule.timestamp
deps-plugin: $(PLUGIN_SUBMODULE)/make.timestamp

%/submodule.timestamp:
	@echo "== submodule: $*"
	git submodule update --init --recursive -- $*
	touch $@

$(K_SUBMODULE)/mvn.timestamp: $(K_SUBMODULE)/submodule.timestamp
	@echo "== building: $*"
	cd $(K_SUBMODULE) && mvn package -DskipTests
	touch $(K_SUBMODULE)/mvn.timestamp

# Building
# --------

MAIN_MODULE:=BEACON-CHAIN
SYNTAX_MODULE:=$(MAIN_MODULE)
MAIN_DEFN_FILE:=beacon-chain
KOMPILE_OPTS?=
LLVM_KOMPILE_OPTS:=$(KOMPILE_OPTS)

llvm_kompiled:=$(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE)-kompiled/interpreter
haskell_kompiled:=$(DEFN_DIR)/haskell/$(MAIN_DEFN_FILE)-kompiled/definition.kore

build: build-llvm build-haskell
build-llvm: $(llvm_kompiled)
build-haskell: $(haskell_kompiled)

# Generate definitions from source files

k_files=$(MAIN_DEFN_FILE).k beacon-chain.k hash-tree.k types.k config.k
llvm_files=$(patsubst %,$(DEFN_DIR)/llvm/%,$(k_files))
haskell_files=$(patsubst %,$(DEFN_DIR)/haskell/%,$(k_files))

defn: llvm-defn haskell-defn
defn-llvm: $(llvm_files)
defn-haskell: $(haskell_files)

$(DEFN_DIR)/llvm/%.k: %.k
	@echo "==  copying: $@"
	mkdir -p $(dir $@)
	cp $< $@

$(DEFN_DIR)/haskell/%.k: %.k
	@echo "==  copying: $@"
	mkdir -p $(dir $@)
	cp $< $@

# LLVM Backend

$(llvm_kompiled): $(llvm_files) $(libff_out)
	@echo "== kompile: $@"
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend llvm                   \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/llvm -I $(DEFN_DIR)/llvm                      \
	                 --hook-namespaces KRYPTO                                              \
	                 -ccopt ${PLUGIN_SUBMODULE}/plugin-c/crypto.cpp                        \
	                 -ccopt -L/usr/local/lib -ccopt -lff -ccopt -lcryptopp                 \
	                 $(addprefix -ccopt ,$(LINK_PROCPS))                                   \
			 -ccopt -g -ccopt -std=c++11 -ccopt -O2                                \
	                 -ccopt -L$(LIBRARY_PATH) -ccopt -I$(INCLUDE_PATH)                     \
	                 $(LLVM_KOMPILE_OPTS)

# Haskell Backend

$(haskell_kompiled): $(haskell_files)
	@echo "== kompile: $@"
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend haskell                   \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/haskell/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/haskell -I $(DEFN_DIR)/haskell

# Testing
# -------

test-split:
	cd $(ETH2_TESTS_SUBMODULE) \
	    && git lfs install     \
	    && git lfs fetch       \
	    && git lfs checkout

TEST_CONCRETE_BACKEND:=llvm

test: test-python-config test-operations-minimal

test-python-config: buildConfig.py $(llvm_kompiled)
	python3 $<

operations_minimal_tests:=$(wildcard tests/eth2.0-spec-tests/tests/minimal/phase0/operations/transfer/pyspec_tests/*/pre.yaml)

test-operations-minimal: $(operations_minimal_tests:=.test-parse)

%.yaml.test-parse: %.yaml $(llvm_kompiled)
	python3 runTest.py parse --pre $*.yaml

# Same as above, but invokes krun with --debug
%.yaml.test-debug: %.yaml $(llvm_kompiled)
	python3 runTest.py parse --pre $*.yaml --debug
