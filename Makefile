# Settings
# --------

BUILD_DIR:=.build
DEFN_DIR:=$(BUILD_DIR)/defn
BUILD_LOCAL:=$(CURDIR)/$(BUILD_DIR)/local
LIBRARY_PATH:=$(BUILD_LOCAL)/lib
C_INCLUDE_PATH:=$(BUILD_LOCAL)/include
CPLUS_INCLUDE_PATH:=$(BUILD_LOCAL)/include
PKG_CONFIG_PATH:=$(LIBRARY_PATH)/pkgconfig
export LIBRARY_PATH
export C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH
export PKG_CONFIG_PATH

DEPS_DIR:=deps
K_SUBMODULE:=$(abspath $(DEPS_DIR)/k)
PANDOC_TANGLE_SUBMODULE:=$(DEPS_DIR)/pandoc-tangle

K_RELEASE:=$(K_SUBMODULE)/k-distribution/target/release/k
K_BIN:=$(K_RELEASE)/bin
K_LIB:=$(K_RELEASE)/lib

PATH:=$(K_BIN):$(PATH)
export PATH

TANGLER:=$(PANDOC_TANGLE_SUBMODULE)/tangle.lua
LUA_PATH:=$(PANDOC_TANGLE_SUBMODULE)/?.lua;;
export TANGLER
export LUA_PATH

TEST_DIR:=tests
ETH2_TESTS_SUBMODULE:=$(TEST_DIR)/eth2.0-specs

.PHONY: all clean \
	    deps deps-k deps-tangle deps-tests \
	    defn defn-llvm \
	    build build-llvm
.SECONDARY:

all: build

clean:
	rm -rf $(BUILD_DIR)

clean-submodules:
	rm -rf $(DEPS_DIR)/k/submodule.timestamp $(DEPS_DIR)/k/mvn.timestamp $(DEPS_DIR)/pandoc-tangle/submodule.timestamp tests/eth2.0-specs/submodule.timestamp

# Dependencies
# ------------

deps: deps-k deps-tangle deps-tests
deps-k: $(K_SUBMODULE)/mvn.timestamp
deps-tangle: $(PANDOC_TANGLE_SUBMODULE)/submodule.timestamp
deps-tests: $(ETH2_TESTS_SUBMODULE)/submodule.timestamp

%/submodule.timestamp:
	@echo "== submodule: $*"
	git submodule update --init -- $*
	touch $@

$(K_SUBMODULE)/mvn.timestamp: $(K_SUBMODULE)/submodule.timestamp
	@echo "== building: $*"
	cd $(K_SUBMODULE) && mvn package -DskipTests -Dhaskell.backend.skip
	touch $(K_SUBMODULE)/mvn.timestamp

# Building
# --------

MAIN_MODULE:=BEACON-CHAIN
SYNTAX_MODULE:=$(MAIN_MODULE)
MAIN_DEFN_FILE:=beacon-chain
KOMPILE_OPTS?=
LLVM_KOMPILE_OPTS:=$(KOMPILE_OPTS) -ccopt -O2

llvm_kompiled:=$(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE)-kompiled/interpreter

build: build-llvm
build-llvm: $(llvm_kompiled)

# Generate definitions from source files

k_files=$(MAIN_DEFN_FILE).k beacon-chain.k
llvm_files=$(patsubst %,$(DEFN_DIR)/llvm/%,$(k_files))

defn: llvm-defn
defn-llvm: $(llvm_files)

$(DEFN_DIR)/llvm/%.k: %.k
	@echo "==  copying: $@"
	mkdir -p $(dir $@)
	cp $< $@

# LLVM Backend

$(llvm_kompiled): $(llvm_files)
	@echo "== kompile: $@"
	$(K_BIN)/kompile --debug --main-module $(MAIN_MODULE) --backend llvm \
	                 --syntax-module $(SYNTAX_MODULE) $(DEFN_DIR)/llvm/$(MAIN_DEFN_FILE).k \
	                 --directory $(DEFN_DIR)/llvm -I $(DEFN_DIR)/llvm \
	                 $(LLVM_KOMPILE_OPTS)

