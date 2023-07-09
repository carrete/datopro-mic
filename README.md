# datopro-mic

This is **NOT** in any way associated with, endorsed by, or affiliated with Cognitect.

With this repo you can run [Datomic Pro](https://datomic.com) v1.0.7021
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

        $ export POSTGRES_USERNAME="postgres" # TODO: Hardcoded by Fly.io.
        $ export POSTGRES_PASSWORD="<an unique, hard to guess string, like an uuid>"
        $ export POSTGRES_DATOMIC_USERNAME="<an unique, hard to guess string, like an uuid>"
        $ export POSTGRES_DATOMIC_PASSWORD="<an unique, hard to guess string, like an uuid>"

        # Use any database name. This database will be created when the
        # transactor starts, if it does not already exist.
        $ export DATOMIC_DATABASE_NAME="carrete"

        $ export DATOMIC_DATABASE_URL="datomic:sql://$DATOMIC_DATABASE_NAME?jdbc:postgresql://datomic-postgres-$SLUG.flycast:5432/datomic?user=$POSTGRES_DATOMIC_USERNAME&password=$POSTGRES_DATOMIC_PASSWORD"

### Run Datomic Pro locally

* First, run Postgres:

        $ make run-postgres

  Keep this running, then (optionally) connect to Postgres at `localhost:5432`

  Postgres must be kept running to use the transactor locally

* Second, run the transactor:

        $ make run-transactor

  Keep this running, then (optionally) use the
  [peer library](https://docs.datomic.com/pro/peer/peer-introduction.html)
  to connect to the transactor at `localhost:4334`

  The transactor must be kept running to use the peer server or console
  locally

* Next, run the peer-server:

        $ make run-peer-server

  Keep this running, then (recommended) use the
  [client library](https://docs.datomic.com/pro/client/client-introduction.html)
  to connect to the peer-server at `localhost:8998`

* Then (optionally) run the console:

        $ make run-console

  Keep this running, then open http://localhost:8999/browse

### Run Datomic Pro on Fly.io

* Change the value of the `CONTAINER_PATH` variable in the top-level Makefile
  from `carrete/datopro-mic` to match your fork of this repo

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
  Fly.io. For improved security, re-set the `DATOMIC_` and `POSTGRES_`
  environment variables above to different values after this step has been
  completed.

  To create the Postgres service on Fly.io, when prompted select
  `Development -  Single node, 1x shared CPU, 256MB RAM, 1GB disk` and answer
  `Y` to `Scale single node pg to zero after one hour?`.

        $ make create-infra set-secrets
        ? Select configuration: Development - Single node, 1x shared CPU, 256MB RAM, 1GB disk
        ? Scale single node pg to zero after one hour? Yes
        Creating postgres cluster in organization personal
        Creating app...
        Setting secrets on app datomic-postgres-30724131...
        Provisioning 1 of 1 machines with image flyio/postgres-flex:15.3@sha256:c380a6108f9f49609d64e5e83a3117397ca3b5c3202d0bf0996883ec3dbb80c8
        Waiting for machine to start...
        Machine 148e75eb313d89 is created
        ==> Monitoring health checks
          Waiting for 148e75eb313d89 to become healthy (started, 3/3)

        Postgres cluster datomic-postgres-30724131 created
          Username:    postgres
          Password:    REDACTED
          Hostname:    datomic-postgres-30724131.internal
          Flycast:     fdaa:2:2cad:0:1::f
          Proxy port:  5432
          Postgres port:  5433
          Connection string: postgres://postgres:REDACTED@datomic-postgres-30724131.flycast:5432

        Save your credentials in a secure place -- you won't be able to see them again!

        Connect to postgres
        Any app within the Tom Vaughan organization can connect to this Postgres using the above connection string

        Now that you've set up Postgres, here's what you need to understand: https://fly.io/docs/postgres/getting-started/what-you-should-know/
        New app created: datomic-transactor-30724131
        New app created: datomic-peer-server-30724131
        New app created: datomic-console-30724131
        ### Set secrets for transactor-30724131
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        Set POSTGRES_USERNAME
        Set POSTGRES_PASSWORD
        Set POSTGRES_DATOMIC_USERNAME
        Set POSTGRES_DATOMIC_PASSWORD
        Set SLUG
        ### Set secrets for peer-server-30724131
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        Set POSTGRES_USERNAME
        Set POSTGRES_PASSWORD
        Set POSTGRES_DATOMIC_USERNAME
        Set POSTGRES_DATOMIC_PASSWORD
        Set SLUG
        ### Set secrets for console-30724131
        Set DATOMIC_ACCESS_KEY_ID
        Set DATOMIC_SECRET_ACCESS_KEY
        Set DATOMIC_DATABASE_NAME
        Set DATOMIC_DATABASE_URL
        Set POSTGRES_USERNAME
        Set POSTGRES_PASSWORD
        Set POSTGRES_DATOMIC_USERNAME
        Set POSTGRES_DATOMIC_PASSWORD
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

  This does not need to be kept running to use the peer server or console on
  Fly.io

* To use the peer-server on Fly.io, run:

        $ make forward-peer-server

  Keep this running, then connect to the peer-server at `localhost:8998`

* To use the console on Fly.io, run:

        $ make forward-console

  Keep this running, then open http://localhost:8999/browse

* To completely remove Datomic Pro from Fly.io, run:

        $ make destroy-infra

* To show the status of the services running on Fly.io, run:

        $ make status
