SET client_min_messages TO WARNING;

CREATE DATABASE datomic WITH
    CONNECTION LIMIT = -1
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    OWNER = :"POSTGRES_USERNAME"
    TABLESPACE = pg_default
    TEMPLATE template0
;

\c datomic

SET DATOMIC.USERNAME TO :"DATOMIC_USERNAME";
SET DATOMIC.PASSWORD TO :'DATOMIC_PASSWORD';

DO $$
BEGIN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L'
        , current_setting('DATOMIC.USERNAME')
        , current_setting('DATOMIC.PASSWORD')
    );
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'The role "%I" already exists. Skipping...'
            , current_setting('DATOMIC.USERNAME')
        ;
END$$;

DO $$
BEGIN
    CREATE TABLE datomic_kvs (
        id text NOT NULL,
        rev integer,
        map text,
        val bytea,
        CONSTRAINT pk_id PRIMARY KEY (id)
    )
    WITH (
        OIDS = FALSE
    );
EXCEPTION
    WHEN duplicate_table THEN
        RAISE NOTICE 'The table "datomic_kvs" already exists. Skipping...';
END$$;

ALTER TABLE datomic_kvs
    OWNER TO :"POSTGRES_USERNAME";

GRANT ALL ON TABLE datomic_kvs
    TO :"POSTGRES_USERNAME";
GRANT ALL ON TABLE datomic_kvs
    TO public;
