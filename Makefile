# There are a couple of conventions we use so make works a little better.
#
# We sometimes want to build an entire directory of files based on one file.
# We do this for dependencies. E.g.: package.json -> node_modules.
# For these cases, we track an empty `.stamp` file in the directory.
# This allows us to keep up with make's dependency model.
#
# We also want some place to store all the excess build artifacts.
# This might be test outputs, or it could be some intermediate artifacts.
# For this, we use the `$(BUILD)` directory.
# Assuming the different tools allow us to put their artifacts in here,
# we can clean up builds really easily: delete this directory.
#
# We use some make syntax that might be unfamiliar, a quick refresher:
# make is based on a set of rules
#
# <targets>: <prerequisites> | <order-only-prerequisites>
# 	<recipe>
#
# `<targets>` are the things we want to make. This is usually a single file,
# but it can be multiple things separated by spaces.
#
# `<prerequisites>` are the things that decide when `<targets>` is out of date.
# These are also usually files. They are separated by spaces.
# If any of the `<prerequisites>` are newer than the `<targets>`,
# the recipe is run to bring the `<targets>` up to date.
#
# `<recipe>` are the commands to run to bring the `<targets>` up to date.
# These are commands like we write on a terminal.
#
# See: https://www.gnu.org/software/make/manual/make.html#Rule-Syntax
#
# `<order-only-prerequisites>` are similar to normal `<prerequisites>`
# but they don't cause a target to be rebuilt if they're out of date.
# This is mostly useful for creating directories and whatnot.
#
# See: https://www.gnu.org/software/make/manual/make.html#Prerequisite-Types
#
# And a quick refresher on some make variables:
#
# $@ - Expands to the target we're building.
# $< - Expands to the first prerequisite of the recipe.
#
# See: https://www.gnu.org/software/make/manual/make.html#Automatic-Variables
#
# `.DEFAULT_GOAL` is the goal to use if no other goals are specified.
# Normally, the first goal in the file is used if no other goals are specified.
# Setting this allows us to override that behavior.
#
# See: https://www.gnu.org/software/make/manual/make.html#index-_002eDEFAULT_005fGOAL-_0028define-default-goal_0029
#
# `.PHONY` forces a recipe to always run. This is useful for things that are
# more like commands than targets. For instance, we might want to clean up
# all artifacts. Since there's no useful target, we can mark `clean` with
# `.PHONY` and make will run the task every time we ask it to.
#
# See: https://www.gnu.org/software/make/manual/make.html#Phony-Targets
# See: https://www.gnu.org/software/make/manual/make.html#index-_002ePHONY-1

ROOT_DIR := $(shell pwd)

# Build directories
BUILD ?= $(ROOT_DIR)/.build
NODE_MODULES_DIR := node_modules
SPAGO_DIR := .spago

# Makefile definitions are mutable, so the order they're defined matters.
# That means this definition needs to come before any variables that use it.
FIND_SRC_FILE_ARGS := \( -name '*.purs' -o -name '*.js' \) -type f

NODE_MODULES_STAMP := $(NODE_MODULES_DIR)/.stamp
SPAGO_CONFIGS := $(shell find . \( ! -regex '.*/\..*' \) -name 'spago.dhall' -type f) # the regex excludes hidden directories
SPAGO_STAMP := $(SPAGO_DIR)/.stamp
SRC_DIR ?= src
SRC_SRCS := $(shell find $(SRC_DIR) $(FIND_SRC_FILE_ARGS))

ALL_SRCS := \
	$(SRC_SRCS)

SPAGO_BUILD_DEPENDENCIES := $(ALL_SRCS) $(NODE_MODULES_STAMP) $(SPAGO_STAMP)

# Allow RTS args to be passed in to override the default behavior.
# We can invoke make like: `RTS_ARGS='+RTS -N16 -RTS' make`.
RTS_ARGS ?= +RTS -N2 -A800m -RTS

# Colors for printing
CYAN := \033[0;36m
RED := \033[0;31m
RESET := \033[0;0m

.DEFAULT_GOAL := build

$(BUILD):
	mkdir -p $@

$(NODE_MODULES_STAMP): package.json package-lock.json
	npm install
	touch $@

$(SPAGO_STAMP): packages.dhall $(SPAGO_CONFIGS) $(NODE_MODULES_STAMP)
	# `spago` doesn't clean up after itself if different versions are installed, so we do it ourselves.
	rm -fr $(SPAGO_DIR)
	npx spago install $(RTS_ARGS)
	touch $@

.PHONY: build
build: $(SPAGO_CONFIGS) $(SPAGO_BUILD_DEPENDENCIES) | $(BUILD)
	npx spago build --purs-args '$(RTS_ARGS)'

.PHONY: test
test: $(SPAGO_CONFIGS) $(SPAGO_BUILD_DEPENDENCIES) | $(BUILD)
	npx spago test --purs-args '$(RTS_ARGS)'
