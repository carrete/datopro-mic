# -*- coding: utf-8; mode: makefile-gmake; -*-

MAKEFLAGS += --warn-undefined-variables

SHELL := bash
.SHELLFLAGS := -euo pipefail -c

HERE := $(shell cd -P -- $(shell dirname -- $$0) && pwd -P)

# https://docs.datomic.com/pro/releases.html
DATOMIC_PRO_VERSION := 1.0.7180
DATOMIC_PRO_DOWNLOAD_URL := https://datomic-pro-downloads.s3.amazonaws.com/$(DATOMIC_PRO_VERSION)/datomic-pro-$(DATOMIC_PRO_VERSION).zip

CONTAINER_PATH := carrete/datopro-mic
CONTAINER_REGISTRY := ghcr.io
CONTAINER_VERSION := $(shell git rev-parse HEAD)

.PHONY: all
all: build

.PHONY: has-command-%
has-command-%:
	@$(if $(shell command -v $* 2> /dev/null),,$(error The command $* does not exist in PATH))

.PHONY: is-defined-%
is-defined-%:
	@$(if $(value $*),,$(error The environment variable $* is undefined))

.PHONY: is-repo-clean
is-repo-clean: has-command-git
	@git diff-index --quiet HEAD --

.PHONY: login
login: has-command-podman is-defined-CONTAINER_REGISTRY is-defined-GITHUB_USERNAME is-defined-GITHUB_PASSWORD
	@echo $$GITHUB_PASSWORD | podman login --username $$GITHUB_USERNAME --password-stdin $(CONTAINER_REGISTRY)

.PHONY: create-network-%
create-network-%: has-command-podman
	@if [[ -z "$(shell podman network inspect --format=CREATED $*)" ]];     \
	then                                                                    \
	    podman network create --driver bridge $*;                           \
	fi                                                                      \

.PHONY: download-datomic-pro
download-datomic-pro: has-command-curl is-defined-DATOMIC_PRO_DOWNLOAD_URL
	@if [[ ! -f datomic-pro.zip ]]; then                                    \
	    curl -s -o datomic-pro.zip $(DATOMIC_PRO_DOWNLOAD_URL);             \
	fi

.PHONY: extract-datomic-pro
extract-datomic-pro: has-command-unzip is-defined-DATOMIC_PRO_VERSION download-datomic-pro
	@if [[ ! -d datomic-pro/datomic-pro ]]; then                            \
	    cd datomic-pro && rm -rf datomic-pro*                               \
	      && unzip -q -o ../datomic-pro.zip                                 \
	      && ln -s datomic-pro-$(DATOMIC_PRO_VERSION) datomic-pro;          \
	fi

.PHONY: build
build: has-command-podman is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_PATH is-defined-CONTAINER_VERSION extract-datomic-pro create-network-datomic
	@podman build -t $(CONTAINER_REGISTRY)/$(CONTAINER_PATH):$(CONTAINER_VERSION) -f Containerfile .

.PHONY: push
push: is-repo-clean has-command-podman is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_PATH is-defined-CONTAINER_VERSION build login
	@podman push $(CONTAINER_REGISTRY)/$(CONTAINER_PATH):$(CONTAINER_VERSION)

.PHONY: run-transactor
run-transactor: is-defined-DATOMIC_STORAGE_ADMIN_PASSWORD is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD is-defined-SLUG build
	@podman run --rm -it --name datomic-transactor-$$SLUG.internal          \
	    --env DATOMIC_STORAGE_ADMIN_PASSWORD=$$DATOMIC_STORAGE_ADMIN_PASSWORD     \
	    --env DATOMIC_STORAGE_DATOMIC_PASSWORD=$$DATOMIC_STORAGE_DATOMIC_PASSWORD \
	    --env SLUG=$$SLUG                                                   \
	    --network datomic                                                   \
	    --publish 4334:4334                                                 \
	    --volume datomic-data:/srv/datomic/data                             \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_PATH):$(CONTAINER_VERSION)        \
	    make $@

.PHONY: run-peer-server
run-peer-server: is-defined-DATOMIC_DATABASE_NAME is-defined-DATOMIC_DATABASE_URL is-defined-DATOMIC_ACCESS_KEY_ID is-defined-DATOMIC_SECRET_ACCESS_KEY is-defined-SLUG build
	@podman run --rm -it --name datomic-peer-server-$$SLUG.internal         \
	    --env DATOMIC_DATABASE_NAME=$$DATOMIC_DATABASE_NAME                 \
	    --env DATOMIC_DATABASE_URL=$$DATOMIC_DATABASE_URL                   \
	    --env DATOMIC_ACCESS_KEY_ID=$$DATOMIC_ACCESS_KEY_ID                 \
	    --env DATOMIC_SECRET_ACCESS_KEY=$$DATOMIC_SECRET_ACCESS_KEY         \
	    --env SLUG=$$SLUG                                                   \
	    --network datomic                                                   \
	    --publish 8998:8998                                                 \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_PATH):$(CONTAINER_VERSION)        \
	    make $@

.PHONY: run-console
run-console: is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD is-defined-SLUG build
	@podman run --rm -it --name datomic-console-$$SLUG.internal             \
	    --env DATOMIC_STORAGE_DATOMIC_PASSWORD=$$DATOMIC_STORAGE_DATOMIC_PASSWORD \
	    --env SLUG=$$SLUG                                                   \
	    --network datomic                                                   \
	    --publish 8999:8999                                                 \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_PATH):$(CONTAINER_VERSION)        \
	    make $@

.PHONY: shell
shell: is-defined-DATOMIC_DATABASE_NAME is-defined-DATOMIC_DATABASE_URL is-defined-DATOMIC_ACCESS_KEY_ID is-defined-DATOMIC_SECRET_ACCESS_KEY is-defined-DATOMIC_STORAGE_ADMIN_PASSWORD is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD is-defined-SLUG build
	@podman run --rm -it --name datomic-shell.internal                      \
	    --env DATOMIC_DATABASE_NAME=$$DATOMIC_DATABASE_NAME                 \
	    --env DATOMIC_DATABASE_URL=$$DATOMIC_DATABASE_URL                   \
	    --env DATOMIC_ACCESS_KEY_ID=$$DATOMIC_ACCESS_KEY_ID                 \
	    --env DATOMIC_SECRET_ACCESS_KEY=$$DATOMIC_SECRET_ACCESS_KEY         \
	    --env DATOMIC_STORAGE_ADMIN_PASSWORD=$$DATOMIC_STORAGE_ADMIN_PASSWORD     \
	    --env DATOMIC_STORAGE_DATOMIC_PASSWORD=$$DATOMIC_STORAGE_DATOMIC_PASSWORD \
	    --env SLUG=$$SLUG                                                   \
	    --network datomic                                                   \
	    --publish 8999:8999                                                 \
	    --volume datomic-data:/srv/datomic/data                             \
	    --volume $(HERE)/datomic-pro:/opt/datomic-pro                       \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_PATH):$(CONTAINER_VERSION)        \
	    make $@

FLY := $(HERE)/.bin/fly

.PHONY: set-slug
set-slug: has-command-sed is-defined-SLUG
	@sed -i "s/@SLUG@/$$SLUG/g" *.toml

.PHONY: create-infra
create-infra: is-defined-FLY_ORGANIZATION is-defined-SLUG set-slug
	@APPS="$$($(FLY) apps list)";                                           \
	for APP in transactor peer-server console; do                           \
	    if ! echo $$APPS | grep -cq datomic-$$APP-$$SLUG; then              \
	        $(FLY) apps create datomic-$$APP-$$SLUG -o $$FLY_ORGANIZATION;  \
	    fi;                                                                 \
	done

.PHONY: destroy-infra
destroy-infra: is-defined-SLUG
	@APPS="$$($(FLY) apps list)";                                           \
	for APP in transactor peer-server console; do                           \
	    if echo $$APPS | grep -cq datomic-$$APP-$$SLUG; then                \
	        $(FLY) apps destroy datomic-$$APP-$$SLUG -y;                    \
	    fi;                                                                 \
	done

.PHONY: set-secrets
set-secrets: export SECRETS=DATOMIC_STORAGE_ADMIN_PASSWORD DATOMIC_STORAGE_DATOMIC_PASSWORD DATOMIC_ACCESS_KEY_ID DATOMIC_SECRET_ACCESS_KEY DATOMIC_DATABASE_NAME DATOMIC_DATABASE_URL SLUG
set-secrets: is-defined-SLUG
	@for APP in transactor peer-server console; do                          \
	    echo "### Set secrets for $$APP-$$SLUG";                            \
	    SECRETS_LIST="$$($(FLY) secrets list -a datomic-$$APP-$$SLUG)";     \
	    for SECRET in $$SECRETS; do                                         \
	        if [[ -n $$(printenv $$SECRET) ]]; then                         \
	            if ! echo $$SECRETS_LIST | grep -cq $$SECRET; then          \
	                $(FLY) secrets set -a datomic-$$APP-$$SLUG              \
			  $$SECRET=$$(printenv $$SECRET) > /dev/null;           \
	                echo "Set $$SECRET";                                    \
	            fi;                                                         \
	        fi;                                                             \
	    done;                                                               \
	done

.PHONY: list-secrets
list-secrets: is-defined-SLUG
	@for APP in transactor peer-server console; do                          \
	    echo "### Secrets set for $$APP-$$SLUG";                            \
	    $(FLY) secrets list -a datomic-$$APP-$$SLUG;                        \
	done

.PHONY: deploy
deploy: is-defined-SLUG create-infra set-secrets
	@for APP in transactor peer-server console; do                          \
	    echo "### Deploy $$APP-$$SLUG";                                     \
	    $(FLY) deploy -c datomic-$$APP.toml --vm-memory 2048                \
	      -i $(CONTAINER_REGISTRY)/$(CONTAINER_PATH):$(CONTAINER_VERSION);  \
	done

.PHONY: status
status: is-defined-SLUG
	@for APP in transactor peer-server console; do                          \
	    echo "### Status of $$APP-$$SLUG";                                  \
	    $(FLY) status -a datomic-$$APP-$$SLUG;                              \
	done

.PHONY: forward-transactor
forward-transactor: export PODMAN_EXTRA_RUN_ARGS=--publish 4334:4334
forward-transactor: is-defined-SLUG
	@$(FLY) proxy 4334:4334 -b 0.0.0.0 -a datomic-transactor-$$SLUG

.PHONY: forward-peer-server
forward-peer-server: export PODMAN_EXTRA_RUN_ARGS=--publish 8998:8998
forward-peer-server: is-defined-SLUG
	@$(FLY) proxy 8998:8998 -b 0.0.0.0 -a datomic-peer-server-$$SLUG

.PHONY: forward-console
forward-console: export PODMAN_EXTRA_RUN_ARGS=--publish 8999:8999
forward-console: is-defined-SLUG
	@$(FLY) proxy 8999:8999 -b 0.0.0.0 -a datomic-console-$$SLUG
