ifndef JAKETS__INCLUDE_BARRIER_
JAKETS__INCLUDE_BARRIER_ = 1

# The following code will be use in almost all of the project makefiles
# before we include any new makefile, the current makefile will be the last
# item in the MAKEFILE_LIST variable. However, the $(dir ) function always
# adds / at the end of the result.
# to make the usage of this variable mroe readable and elegant, we add
# and extra / at the end to differentiate it from / in the middle of the path
# thre relpace // with nothing.
JAKETS__DIR := $(subst //,,$(dir $(lastword $(MAKEFILE_LIST)))/)
CURRENT__DIR := $(subst //,,$(dir $(firstword $(MAKEFILE_LIST)))/)

#overwritable values
LOG_LEVEL?=0
PARALLEL_LIMIT?=0
EXPECTED_NODE_VERSION?=v12.11.0
NODE__DIR?=./build/nodejs
###################################################################################################
# setup platform dependent variables
#
SHELL := /bin/bash
UNAME := $(shell uname)
NULL = /dev/null
WGET = wget --directory-prefix=$(NODE__DIR)
EXTRACT = tar xvf --strip-components=1

ifeq ($(UNAME), Linux)
	NODE_DIST__NAME = node-$(EXPECTED_NODE_VERSION)-linux-x64.tar.gz
	NODE_BIN__DIR = $(NODE__DIR)/bin
else ifeq ($(UNAME), Darwin)
	NODE_DIST__NAME = node-$(EXPECTED_NODE_VERSION)-darwin-x64.tar.gz
	NODE_BIN__DIR = $(NODE__DIR)/bin
else 
# ifeq($(UNAME), MINGW32_NT-6.2)
	# NULL = $$null
	NODE_DIST__NAME = node-$(EXPECTED_NODE_VERSION)-win-x64.zip
	NODE_BIN__DIR = $(NODE__DIR)
	WGET += --no-check-certificate
	EXTRACT = Expand-Archive -DestinationPath $(NODE__DIR)
endif
NODE_DIST_LOCAL__FILE = $(NODE__DIR)/$(NODE_DIST__NAME)
NODE_DIST_REMOTE__FILE = https://nodejs.org/dist/$(EXPECTED_NODE_VERSION)/$(NODE_DIST__NAME)

#
###################################################################################################


NODE := node
NPM := npm

NODE_BIN__FILE =
INSTALLED_NODE_VERSION = $(shell $(NODE) --version 2>$(NULL))
ifneq "$(INSTALLED_NODE_VERSION)" "$(EXPECTED_NODE_VERSION)"
  SEMVER_ERROR := $(shell $(NODE) -e "try{ require('semver'); } catch(e) { console.log('error'); }" 2>$(NULL))
  ifneq "$(SEMVER_ERROR)" ""
    SEMVER_ERROR := $(shell $(NPM) install --no-save semver )
  endif

  # INSTALLED_NODE_VERSION = $(EXPECTED_NODE_VERSION)
  # IS_NEWER_NODE_VERSION := $(shell $(NODE) -e "console.log(require('semver').satisfies('$(INSTALLED_NODE_VERSION)','$(EXPECTED_NODE_VERSION)'))" 2>$(NULL))
  IS_NEWER_NODE_VERSION := $(shell $(NODE) -e "console.log(require('semver').gt('$(INSTALLED_NODE_VERSION)','$(EXPECTED_NODE_VERSION)'))" 2>$(NULL))
  ifeq "$(IS_NEWER_NODE_VERSION)" "true"
    $(info using installed node $(INSTALLED_NODE_VERSION))
  else
    $(info using local node $(EXPECTED_NODE_VERSION))
    NODE_BIN__FILE = $(NODE_BIN__DIR)/$(NODE)
    export PATH := $(PWD)/$(NODE_BIN__DIR):$(PATH)
    $(info PATH=$(PATH))
  endif
else
  $(info using installed node $(INSTALLED_NODE_VERSION))
endif


# NODE_MODULES__DIR=$(JAKETS__DIR)/node_modules
NODE_MODULES__DIR ?= $(CURRENT__DIR)/node_modules
NODE_MODULES__UPDATE_INDICATOR=$(NODE_MODULES__DIR)/.node_modules_updated
NODE_MODULES__NPM_INSTALL_INDICATOR=$(NODE_MODULES__DIR)/.node_modules_npm_install
POST_NPM_INSTALL=
# JAKE = $(NODE_MODULES__DIR)/.bin/jake
JAKE__PARAMS += LogLevel=$(LOG_LEVEL) ParallelLimit=$(PARALLEL_LIMIT) --trace
# TSC = $(NODE_MODULES__DIR)/.bin/tsc
# TS_NODE = $(NODE_MODULES__DIR)/.bin/ts-node
# JAKETS ?= $(NODE_MODULES__DIR)/.bin/jakets

#One can use the following local file to overwrite the above settings
-include LocalPaths.mk

###################################################################################################
# setup and rules in the current working directory
#

# default: run_jake

JAKETS_JAKEFILE__JS=$(JAKETS__DIR)/Jakefile.js
ifneq ($(JAKETS__DIR),$(CURRENT__DIR))
  LOCAL_JAKEFILE__JS=Jakefile.js
endif

jts_run_jake: $(NODE_MODULES__UPDATE_INDICATOR) _jts_jakets_bin
	$(JAKETS) -- $(JAKE__PARAMS)

j-%: $(NODE_MODULES__UPDATE_INDICATOR) _jts_jakets_bin
	$(JAKETS) -- $* $(JAKE__PARAMS)

define find_jakets
	$(eval JAKETS ?= $(firstword $(shell $(NODE) -e "try {console.log(require.resolve('.bin/jakets').replace(/\\\/g, '/'))}catch(e){console.log('npx jakets')}")) $(NODE_MODULES__DIR)/.bin/jakets)
	$(info JAKETS=$(JAKETS))
endef

_jts_jakets_bin: $(NODE_MODULES__UPDATE_INDICATOR)
	$(call find_jakets)


# jts_run_jake: jts_compile_jake
# 	$(JAKE) --jakefile $(JAKETS_JAKEFILE__JS) jts:setup $(JAKE__PARAMS)
# 	$(JAKE) $(JAKE__PARAMS)

# j-%: jts_compile_jake
# 	$(JAKE) --jakefile $(JAKETS_JAKEFILE__JS) jts:setup $(JAKE__PARAMS)
# 	$(JAKE) $* $(JAKE__PARAMS)

#The following is auto generated to make sure local Jakefile.ts dependencies are captured properly
-include Jakefile.dep.mk

$(JAKE_TASKS):%: j-%

jts_setup: jts_compile_jake

jts_compile_jake: $(JAKETS_JAKEFILE__JS)
# jts_compile_jake: $(JAKETS_JAKEFILE__JS) $(LOCAL_JAKEFILE__JS)

#
###################################################################################################


###################################################################################################
# setup in jakets directory
#

# $(LOCAL_JAKEFILE__JS): $(JAKE) $(JAKETS_JAKEFILE__JS) $(filter-out Jakefile.dep.mk, $(MAKEFILE_LIST))
# 	$(JAKE) --jakefile $(JAKETS_JAKEFILE__JS) jts:setup $(JAKE__PARAMS)

$(JAKETS_JAKEFILE__JS): $(NODE_MODULES__UPDATE_INDICATOR) $(wildcard $(JAKETS__DIR)/*.ts)
	$(NPM) run build

# $(JAKETS_JAKEFILE__JS): $(JAKE) $(TSC) $(wildcard $(JAKETS__DIR)/*.ts)
# 	$(TSC) -p $(JAKETS__DIR)/tsconfig.json
# 	$(JAKE) --jakefile $(JAKETS_JAKEFILE__JS) jts:setup $(JAKE__PARAMS)
# 	touch $@

# jts_get_tools: $(TSC)

# $(JAKE): $(NODE_MODULES__UPDATE_INDICATOR)
# 	if [ ! -f $@ ]; then $(NPM) install --no-save jake; fi
# 	@echo found jake @ `node -e "console.log(require.resolve('jake'))"`
# 	touch $@

# $(TSC): $(NODE_MODULES__UPDATE_INDICATOR)
# 	if [ ! -f $@ ]; then $(NPM) install --no-save typescript; fi
# 	@echo found typescript @ `node -e "console.log(require.resolve('typescript'))"`
# 	touch $@

# $(TS_NODE): $(NODE_MODULES__UPDATE_INDICATOR)
# 	if [ ! -f $@ ]; then $(NPM) install --no-save ts-node; fi
# 	@echo found ts-node @ `node -e "console.log(require.resolve('ts-node'))"`
# 	touch $@

$(NODE_MODULES__UPDATE_INDICATOR): $(NODE_MODULES__NPM_INSTALL_INDICATOR)
	touch $@

npm_update: $(NODE_BIN__FILE)
	$(NPM) update --no-save --depth 999
	$(NPM) dedup
	$(POST_NPM_INSTALL)
	touch $(NODE_MODULES__NPM_INSTALL_INDICATOR)

_jts_npm_install: $(NODE_MODULES__NPM_INSTALL_INDICATOR)

$(NODE_MODULES__NPM_INSTALL_INDICATOR): $(NODE_BIN__FILE) $(wildcard package.json)
	$(NPM) install
	$(call find_jakets)
	$(POST_NPM_INSTALL)
	touch $@

_jts_get_node: $(NODE_BIN__FILE)

$(NODE_BIN__FILE): $(NODE_DIST_LOCAL__FILE) $(CURRENT__DIR)/Makefile
	cd $(NODE__DIR) && \
	tar xvf $(NODE_DIST__NAME) --strip-components=1
	touch $@

$(NODE_DIST_LOCAL__FILE):
	mkdir -p $(NODE__DIR)
	$(WGET) $(NODE_DIST_REMOTE__FILE)
	touch $@

#
###################################################################################################



###################################################################################################
# Rules for debugging/validation
#

# Each makefile that wants to show the variables of the makefile can do the following
# Create a phony target that depends on the print-% where % is replaced by the name of variables
# Example:
.PHONY: show_vars
show_vars: $(patsubst %,print-%, \
          LOG_LEVEL \
          PARALLEL_LIMIT \
          JAKETS__DIR \
          CURRENT__DIR \
          JAKETS_JAKEFILE__JS \
          LOCAL_JAKEFILE__JS \
          AUTOGEN_MODULES \
          UNAME \
          NULL \
          EXPECTED_NODE_VERSION \
          INSTALLED_NODE_VERSION \
          NODE__DIR \
          NODE_BIN__FILE \
          NODE_DIST__NAME \
          NODE_DIST_LOCAL__FILE \
          NODE_DIST_REMOTE__FILE \
          NODE \
          NPM \
          JAKE \
          PATH \
          )
	@echo --------------------------------------------------------------------------------^^^jakets^^^

print-%:
	$(info --------------------------------------------------------------------------------)
	$(info  $* = $($*))
#
###################################################################################################
endif
