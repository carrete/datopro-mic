# datopro-mic

This is **NOT** in any way associated with, endorsed by, or affiliated with Cognitect.

With this repo, you can deploy [Datomic Pro](https://www.datomic.com)
v1.0.6735 to [Fly.io](https://fly.io). To make use of this deployment, deploy
an application to the same Fly.io organization as Datomic Pro, or
[forward connections](https://fly.io/docs/flyctl/proxy/) to the peer server.
The Datomic Console will be made publicly available over the internet, but
this will be required to be proxied too in the future.

**Caveat Emptor:** This is just an experiment and might disappear.

## Quick Start

* Install [Podman](https://podman.io)

* Fork this repo

* Set some environment variables

        # Fly.io requires app names to be unique across all accounts
        # worldwide. This slug will be appended to the app names created on
        # Fly.io, and to the container names when run locally. This slug does
        # not need to be rememberable. A GitHub username would work, if
        # another user on Fly.io hasn't already used it.
        export SLUG="<a short, unique string, e.g. `openssl rand -hex 4`>"

        export DATOMIC_ACCESS_KEY_ID="<an unique, hard to guess string, like an uuid>"
        export DATOMIC_SECRET_ACCESS_KEY="<an unique, hard to guess string, like an uuid>"

        # Use any database name. This database will be created when the
        # transactor starts, if it does not already exist.
        export DATOMIC_DATABASE_NAME="test"

        export DATOMIC_STORAGE_ADMIN_PASSWORD="<an unique, hard to guess string, like an uuid>"
        export DATOMIC_STORAGE_DATOMIC_PASSWORD="<an unique, hard to guess, like an uuid>"

        export DATOMIC_DATABASE_URL="datomic:dev://datomic-transactor-$SLUG.internal:4334/$DATOMIC_DATABASE_NAME?password=$DATOMIC_STORAGE_DATOMIC_PASSWORD"

### To run this locally...

* Run Datomic Pro locally

  In three separate terminal windows, run `make run-transactor`, `make
  run-peer-server`, and `make run-console`. Leave these running, then open
  `http://localhost:8999/browse`

### To run this on Fly.io...

* [Create a Fly.io Access Token](https://fly.io/user/personal_access_tokens)

* Set some additional environment variables

        # Use the same Fly.io Access Token created above.
        export FLY_ACCESS_TOKEN="fo1_GK..qz"
        # Use any Fly.io organization name to which you belong.
        export FLY_ORGANIZATION="personal"

* Set the `FLY_ACCESS_TOKEN`, `FLY_ORGANIZATION`, and `SLUG` secret variables
  [on GitHub](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)

* Change the value of the `CONTAINER_SLUG` variable in the top-level Makefile
  from `carrete/datopro-mic` to your fork of the this repo

* Setup the infrastructure on Fly.io

  This only needs to be run once, and sets the same environment variables on
  Fly.io. For improved security, re-set the `DATOMIC_` environment variables
  above to different values after this step has been completed.

        $ make create-infra set-secrets
        New app created: datomic-transactor-150b16c9
        New app created: datomic-peer-server-150b16c9
        New app created: datomic-console-150b16c9
        ### transactor
        Set DATOMIC_STORAGE_ADMIN_PASSWORD
        Set DATOMIC_STORAGE_DATOMIC_PASSWORD
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        ### peer-server
        Set DATOMIC_STORAGE_ADMIN_PASSWORD
        Set DATOMIC_STORAGE_DATOMIC_PASSWORD
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        ### console
        Set DATOMIC_STORAGE_ADMIN_PASSWORD
        Set DATOMIC_STORAGE_DATOMIC_PASSWORD
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL

* Push your changes to GitHub

  The GitHub Action in this repo will create a Datomic Pro container image,
  push this to the GitHub container image registry associated with this repo,
  and update the virtual machines on Fly.io to use the newly built container
  image. Each merge into the `main` branch will automatically trigger a new
  deployment to Fly.io.

* Access the Datomic Console

  Open `https://datomic-console-$SLUG.fly.dev`

* Delete the infrastructure on Fly.io

        $ make destroy-infra
