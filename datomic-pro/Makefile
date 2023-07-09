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

IS_IN_CONTAINER ?= 0

define CONTAINER_REQUIRED_MESSAGE

This command must be run *inside* the container. Please use the Makefile in
the top-level directory of this project instead
endef

.PHONY: is-in-container
is-in-container:
ifneq ($(IS_IN_CONTAINER),1)
	@$(if $(shell grep -cs dumb-init /proc/1/cmdline),,$(error $(CONTAINER_REQUIRED_MESSAGE)))
endif

.PHONY: shell
shell: is-in-container has-command-bash
	@bash --login

.PHONY: setup-postgres
setup-postgres: is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-POSTGRES_DATOMIC_USERNAME is-defined-POSTGRES_DATOMIC_PASSWORD is-defined-SLUG
	@psql -qf setup-postgres.sql                                            \
	    --set POSTGRES_USERNAME=$$POSTGRES_USERNAME                         \
	    --set DATOMIC_USERNAME=$$POSTGRES_DATOMIC_USERNAME                  \
	    --set DATOMIC_PASSWORD=$$POSTGRES_DATOMIC_PASSWORD                  \
	    postgresql://$$POSTGRES_USERNAME:$$POSTGRES_PASSWORD@datomic-postgres-$$SLUG.flycast

.PHONY: transactor.properties
transactor.properties: is-in-container is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-SLUG
	@cat transactor.properties.in                                           \
	    | sed -e "s#@POSTGRES_USERNAME@#$$POSTGRES_USERNAME#"               \
	    | sed -e "s#@POSTGRES_PASSWORD@#$$POSTGRES_PASSWORD#"               \
	    | sed -e "s#@SLUG@#$$SLUG#"                                         \
	    > /tmp/transactor.properties

.PHONY: run-transactor
run-transactor: is-in-container setup-postgres transactor.properties
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
run-console: is-defined-POSTGRES_USERNAME is-defined-POSTGRES_PASSWORD is-defined-SLUG is-in-container
	@datomic-pro/bin/console -p 8999 datomic-transactor-$$SLUG "datomic:sql://?jdbc:postgresql://datomic-postgres-$$SLUG.flycast:5432/datomic?user=$$POSTGRES_USERNAME&password=$$POSTGRES_PASSWORD"
