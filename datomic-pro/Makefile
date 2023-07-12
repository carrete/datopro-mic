# -*- coding: utf-8; mode: makefile-gmake; -*-

MAKEFLAGS += --warn-undefined-variables

SHELL := bash
.SHELLFLAGS := -euo pipefail -c

HERE := $(shell cd -P -- $(shell dirname -- $$0) && pwd -P)

.PHONY: all
all: run-transactor

.PHONY: has-command-%
has-command-%:
	@$(if $(shell command -v $* 2> /dev/null),,$(error The command $* does not exist in PATH))

.PHONY: is-defined-%
is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

define CONTAINER_REQUIRED_MESSAGE

This command must be run *inside* the container. Please use the Makefile in
the top-level directory of this project instead
endef

.PHONY: is-in-container
is-in-container:
	@$(if $(shell ls /.fly /run/.containerenv 2>/dev/null),,$(error $(CONTAINER_REQUIRED_MESSAGE)))

.PHONY: shell
shell: is-in-container has-command-bash
	@bash --login

.PHONY: transactor.properties
transactor.properties: is-in-container is-defined-DATOMIC_STORAGE_ADMIN_PASSWORD is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD is-defined-SLUG
	@cat transactor.properties.in                                           \
	    | sed -e "s#@STORAGE_ADMIN_PASSWORD@#$$DATOMIC_STORAGE_ADMIN_PASSWORD#"     \
	    | sed -e "s#@STORAGE_DATOMIC_PASSWORD@#$$DATOMIC_STORAGE_DATOMIC_PASSWORD#" \
	    | sed -e "s#@SLUG@#$$SLUG#"                                         \
	    > /tmp/transactor.properties

.PHONY: run-transactor
run-transactor: is-in-container transactor.properties
	@datomic-pro/bin/transactor /tmp/transactor.properties

.PHONY: createdb
createdb: is-in-container is-defined-DATOMIC_DATABASE_URL
	@datomic-pro/bin/run -i $(HERE)/createdb.clj

.PHONY: run-peer-server
run-peer-server: is-in-container is-defined-DATOMIC_ACCESS_KEY_ID is-defined-DATOMIC_SECRET_ACCESS_KEY is-defined-DATOMIC_DATABASE_NAME is-defined-DATOMIC_DATABASE_URL createdb
	@datomic-pro/bin/run -m datomic.peer-server                             \
	    -a $$DATOMIC_ACCESS_KEY_ID,$$DATOMIC_SECRET_ACCESS_KEY              \
	    -d $$DATOMIC_DATABASE_NAME,$$DATOMIC_DATABASE_URL                   \
	    -h 0.0.0.0 -p 8998                                                  \
	    #

.PHONY: run-console
run-console: is-in-container is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD is-defined-SLUG
	@datomic-pro/bin/console -p 8999 localhost datomic:dev://datomic-transactor-$$SLUG.internal:4334?password=$$DATOMIC_STORAGE_DATOMIC_PASSWORD
