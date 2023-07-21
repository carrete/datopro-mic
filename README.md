# datopro-mic

This is **NOT** in any way associated with, endorsed by, or affiliated with Cognitect.

With this repo you can run [Datomic Pro](https://datomic.com) v1.0.6735
locally or on [Fly.io](https://fly.io). The transactor, peer-server, and
console can be connected to on localhost on ports 4334, 8998, and 8999
respectively, regardless of where they are run.

## Quick Start

* Install [Podman](https://podman.io)

* Fork this repo

* Set some environment variables

        # Fly.io requires app names to be unique across all accounts
        # worldwide. This slug will be appended to the app names created on
        # Fly.io, and to the container names when run locally.
        $ export SLUG="<a short, unique string, e.g. `openssl rand -hex 4`>"

        $ export DATOMIC_ACCESS_KEY_ID="<an unique, hard to guess string, like an uuid>"
        $ export DATOMIC_SECRET_ACCESS_KEY="<an unique, hard to guess string, like an uuid>"

        $ export DATOMIC_STORAGE_ADMIN_PASSWORD="<an unique, hard to guess string, like an uuid>"
        $ export DATOMIC_STORAGE_DATOMIC_PASSWORD="<an unique, hard to guess, like an uuid>"

        # Use any database name. This database will be created when the
        # transactor starts, if it does not already exist.
        $ export DATOMIC_DATABASE_NAME="carrete"

        $ export DATOMIC_DATABASE_URL="datomic:dev://datomic-transactor-$SLUG.internal:4334/$DATOMIC_DATABASE_NAME?password=$DATOMIC_STORAGE_DATOMIC_PASSWORD"

### Run Datomic Pro locally

* To use the transactor locally, run:

        $ make run-transactor

  Keep this running, then connect to the transactor at `localhost:4334`

* To use the peer-server locally, run:

        $ make run-peer-server

  Keep this running, then connect to the peer-server at `localhost:8998`

* To use the console locally, run:

        $ make run-console

  Keep this running, then open http://localhost:8999/browse

### Run Datomic Pro on Fly.io

* Change the value of the `CONTAINER_PATH` variable in the top-level Makefile
  from `carrete/datopro-mic` to match your fork of the this repo

* [Create a Fly.io Access Token](https://fly.io/user/personal_access_tokens)

* Set some additional environment variables

        # Use the same Fly.io Access Token created above
        $ export FLY_ACCESS_TOKEN="fo1_GK...REDACTED...qz"
        # Use any Fly.io organization name that you have access to
        $ export FLY_ORGANIZATION="personal"

* Set the `FLY_ACCESS_TOKEN`, `FLY_ORGANIZATION`, and `SLUG` secret variables
  [on GitHub](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)

* Create the infrastructure on Fly.io

  This only needs to be run once, and sets the same environment variables on
  Fly.io. For improved security, re-set the `DATOMIC_` environment variables
  above to different values after this step has been completed.

        $ make create-infra set-secrets
        New app created: datomic-transactor-30724131
        New app created: datomic-peer-server-30724131
        New app created: datomic-console-30724131
        ### Set secrets for transactor-30724131
        Set DATOMIC_STORAGE_ADMIN_PASSWORD
        Set DATOMIC_STORAGE_DATOMIC_PASSWORD
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        Set SLUG
        ### Set secrets for peer-server-30724131
        Set DATOMIC_STORAGE_ADMIN_PASSWORD
        Set DATOMIC_STORAGE_DATOMIC_PASSWORD
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        Set SLUG
        ### Set secrets for console-30724131
        Set DATOMIC_STORAGE_ADMIN_PASSWORD
        Set DATOMIC_STORAGE_DATOMIC_PASSWORD
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        Set SLUG

* Push your changes to GitHub

  The GitHub Action in this repo will create a Datomic Pro container image,
  push this to the GitHub container image registry associated with this repo,
  and update the virtual machines on Fly.io to use the newly built container
  image. Each merge into the `main` branch will automatically trigger a new
  deployment to Fly.io.

* To use the transactor on Fly.io, run:

        $ make forward-transactor

  Keep this running, then connect to the transactor at `localhost:4334`

* To use the peer-server on Fly.io, run:

        $ make forward-peer-server

  Keep this running, then connect to the peer-server at `localhost:8998`

* To use the console on Fly.io, run:

        $ make forward-console

  Keep this running, then open http://localhost:8999/browse

* To completely remove Datomic Pro from Fly.io, run:

        $ make destroy-infra
