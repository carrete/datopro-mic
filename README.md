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

* [Create a Fly.io Access Token](https://fly.io/user/personal_access_tokens)

* Set the `FLY_ACCESS_TOKEN` secret variable
  [on GitHub](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)

* Change the value of the `CONTAINER_SLUG` variable in the top-level Makefile

  Change `carrete/datopro-mic` to point to your fork of the this repo.

* Change the app names

  Fly.io requires app names to be unique across all accounts worldwide.
  Replace `XXX` below with an unique string, like your GitHub username.

        for APP in transactor peer-server console; do
            perl -pi -e "s#datomic-$APP#datomic-$APP-XXX#g" *.toml Makefile datomic-pro/Makefile datomic-pro/transactor.properties.in
        done

* Set some environment variables

        export FLY_ACCESS_TOKEN="<value of Fly.io Access Token created above>"
        # Use any Fly.io organization name to which you belong.
        export FLY_ORGANIZATION="personal"

        export DATOMIC_ACCESS_KEY_ID="<a random string, like an uuid>"
        export DATOMIC_SECRET_ACCESS_KEY="<a random string, like an uuid>"

        # Use any database name. This database will be created when the
        # transactor starts, if it does not already exist.
        export DATOMIC_DATABASE_NAME="test"

        export DATOMIC_STORAGE_ADMIN_PASSWORD="<a random string, like an uuid>"
        export DATOMIC_STORAGE_DATOMIC_PASSWORD="<a random string, like an uuid>"

        # Replace `XXX` below with the same value used in the change app names
        # step above.
        export DATOMIC_DATABASE_URL="datomic:dev://datomic-transactor-XXX.internal:4334/$DATOMIC_DATABASE_NAME?password=$DATOMIC_STORAGE_DATOMIC_PASSWORD"

* Setup the infrastructure on Fly.io

  This only needs to be run once, and sets the same environment variables on
  Fly.io. For improved security, re-set the `DATOMIC_` environment variables
  above to different values after this step has been completed.

        $ make create-infra set-secrets
        New app created: datomic-transactor
        New app created: datomic-peer-server
        New app created: datomic-console
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
  push this to the GitHub container registry associated with this repo, and
  update the virtual machines on Fly.io to use the newly built container
  image.

* Access the Datomic Console

  Again, replace `XXX` below with the same value used in the change app names
  step above.

  Open `https://datomic-console-XXX.fly.dev`

* Delete the infrastructure on Fly.io

        $ make destroy-infra

* Run Datomic Pro locally

  In three separate terminal windows, run `make run-transactor`, `make
  run-peer-server`, and `make run-console`. Leave these running, then open
  `http://localhost:8999/browse`.
