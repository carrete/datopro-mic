# -*- coding: utf-8; mode: makefile-gmake; -*-

MAKEFLAGS += --warn-undefined-variables

SHELL := bash
.SHELLFLAGS := -euo pipefail -c

HERE := $(shell cd -P -- $(shell dirname -- $$0) && pwd -P)

# https://docs.datomic.com/pro/releases.html
DATOMIC_PRO_VERSION := 1.0.6733
DATOMIC_PRO_DOWNLOAD_URL := https://datomic-pro-downloads.s3.amazonaws.com/$(DATOMIC_PRO_VERSION)/datomic-pro-$(DATOMIC_PRO_VERSION).zip

CONTAINER_SLUG := carrete/datopro-mic
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
	    curl $(DATOMIC_PRO_DOWNLOAD_URL) -o datomic-pro.zip;                \
	fi

.PHONY: extract-datomic-pro
extract-datomic-pro: has-command-unzip is-defined-DATOMIC_PRO_VERSION download-datomic-pro
	@if [[ ! -d datomic-pro/datomic-pro ]]; then                            \
	    cd datomic-pro && rm -rf datomic-pro*                               \
	      && unzip -q -o ../datomic-pro.zip                                 \
	      && ln -s datomic-pro-$(DATOMIC_PRO_VERSION) datomic-pro;          \
	fi

.PHONY: build
build: has-command-podman is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION extract-datomic-pro create-network-datomic
	@podman build -t $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION) -f Containerfile .

.PHONY: push
push: is-repo-clean has-command-podman is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION build login
	@podman push $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)

.PHONY: run-transactor
run-transactor: is-defined-DATOMIC_STORAGE_ADMIN_PASSWORD is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD build
	@podman run --rm -it --name datomic-transactor.internal                 \
	    --env DATOMIC_STORAGE_ADMIN_PASSWORD=$$DATOMIC_STORAGE_ADMIN_PASSWORD     \
	    --env DATOMIC_STORAGE_DATOMIC_PASSWORD=$$DATOMIC_STORAGE_DATOMIC_PASSWORD \
	    --network datomic                                                   \
	    --volume datomic-data:/srv/datomic/data                             \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)        \
	    make $@

.PHONY: run-peer-server
run-peer-server: is-defined-DATOMIC_DATABASE_NAME is-defined-DATOMIC_DATABASE_URL is-defined-DATOMIC_ACCESS_KEY_ID is-defined-DATOMIC_SECRET_ACCESS_KEY build
	@podman run --rm -it --name datomic-peer-server.internal                \
	    --env DATOMIC_DATABASE_NAME=$$DATOMIC_DATABASE_NAME                 \
	    --env DATOMIC_DATABASE_URL=$$DATOMIC_DATABASE_URL                   \
	    --env DATOMIC_ACCESS_KEY_ID=$$DATOMIC_ACCESS_KEY_ID                 \
	    --env DATOMIC_SECRET_ACCESS_KEY=$$DATOMIC_SECRET_ACCESS_KEY         \
	    --network datomic                                                   \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)        \
	    make $@

.PHONY: run-console
run-console: is-defined-DATOMIC_DATABASE_NAME is-defined-DATOMIC_DATABASE_URL is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD build
	@podman run --rm -it --name datomic-console.internal                    \
	    --env DATOMIC_DATABASE_NAME=$$DATOMIC_DATABASE_NAME                 \
	    --env DATOMIC_DATABASE_URL=$$DATOMIC_DATABASE_URL                   \
	    --env DATOMIC_STORAGE_DATOMIC_PASSWORD=$$DATOMIC_STORAGE_DATOMIC_PASSWORD \
	    --network datomic                                                   \
	    --publish 8999:8999                                                 \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)        \
	    make $@

.PHONY: shell
shell: is-defined-DATOMIC_DATABASE_NAME is-defined-DATOMIC_DATABASE_URL is-defined-DATOMIC_ACCESS_KEY_ID is-defined-DATOMIC_SECRET_ACCESS_KEY is-defined-DATOMIC_STORAGE_ADMIN_PASSWORD is-defined-DATOMIC_STORAGE_DATOMIC_PASSWORD build
	@podman run --rm -it --name datomic-shell.internal                      \
	    --env DATOMIC_DATABASE_NAME=$$DATOMIC_DATABASE_NAME                 \
	    --env DATOMIC_DATABASE_URL=$$DATOMIC_DATABASE_URL                   \
	    --env DATOMIC_ACCESS_KEY_ID=$$DATOMIC_ACCESS_KEY_ID                 \
	    --env DATOMIC_SECRET_ACCESS_KEY=$$DATOMIC_SECRET_ACCESS_KEY         \
	    --env DATOMIC_STORAGE_ADMIN_PASSWORD=$$DATOMIC_STORAGE_ADMIN_PASSWORD     \
	    --env DATOMIC_STORAGE_DATOMIC_PASSWORD=$$DATOMIC_STORAGE_DATOMIC_PASSWORD \
	    --network datomic                                                   \
	    --publish 8999:8999                                                 \
	    --volume datomic-data:/srv/datomic/data                             \
	    --volume $(HERE)/datomic-pro:/opt/datomic-pro                       \
	    $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION)        \
	    make $@

FLY := $(HERE)/contrib/fly

.PHONY: create-infra
create-infra: is-defined-FLY_ORGANIZATION
	@APPS="$$($(FLY) apps list)";                                           \
	for APP in transactor peer-server console; do                           \
	    if ! echo $$APPS | grep -cq datomic-$$APP; then                     \
	        $(FLY) apps create datomic-$$APP -o $$FLY_ORGANIZATION;         \
	    fi;                                                                 \
	done

.PHONY: destroy-infra
destroy-infra:
	@APPS="$$($(FLY) apps list)";                                           \
	for APP in transactor peer-server console; do                           \
	    if echo $$APPS | grep -cq datomic-$$APP; then                       \
	        $(FLY) apps destroy datomic-$$APP -y;                           \
	    fi;                                                                 \
	done

.PHONY: set-secrets
set-secrets: export SECRETS=DATOMIC_STORAGE_ADMIN_PASSWORD DATOMIC_STORAGE_DATOMIC_PASSWORD DATOMIC_ACCESS_KEY_ID DATOMIC_SECRET_ACCESS_KEY DATOMIC_DATABASE_NAME DATOMIC_DATABASE_URL
set-secrets:
	@for APP in transactor peer-server console; do                          \
	    SECRETS_LIST="$$($(FLY) secrets list -a datomic-$$APP)";            \
	    for SECRET in $$SECRETS; do                                         \
	        if [[ -n $$(printenv $$SECRET) ]]; then                         \
	            if ! echo $$SECRETS_LIST | grep -cq $$SECRET; then          \
	                $(FLY) secrets set -a datomic-$$APP                     \
			  $$SECRET=$$(printenv $$SECRET);                       \
	            fi;                                                         \
	        fi;                                                             \
	    done;                                                               \
	done

.PHONY: list-secrets
list-secrets:
	@for APP in transactor peer-server console; do                          \
	    echo "### $$APP";                                                   \
	    $(FLY) secrets list -a datomic-$$APP;                               \
	done

.PHONY: deploy
deploy: is-defined-CONTAINER_REGISTRY is-defined-CONTAINER_SLUG is-defined-CONTAINER_VERSION create-infra set-secrets
	@for APP in transactor peer-server console; do                          \
	    $(FLY) deploy -c datomic-$$APP.toml --vm-memory 2048                \
	      -i $(CONTAINER_REGISTRY)/$(CONTAINER_SLUG):$(CONTAINER_VERSION);  \
	done
