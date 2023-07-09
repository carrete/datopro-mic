-- Database: datomic

-- DROP DATABASE datomic;

CREATE DATABASE datomic
WITH OWNER = :"postgres_username"
      TEMPLATE template0
      ENCODING = 'UTF8'
      TABLESPACE = pg_default
      LC_COLLATE = 'en_US.UTF-8'
      LC_CTYPE = 'en_US.UTF-8'
      CONNECTION LIMIT = -1;

\c datomic

-- DROP ROLE :username

CREATE ROLE :"datomic_username" LOGIN PASSWORD :'datomic_password';

-- Table: datomic_kvs

-- DROP TABLE datomic_kvs;

CREATE TABLE datomic_kvs
(
 id text NOT NULL,
 rev integer,
 map text,
 val bytea,
 CONSTRAINT pk_id PRIMARY KEY (id )
)
WITH (
 OIDS=FALSE
);
ALTER TABLE datomic_kvs
 OWNER TO :"postgres_username";
GRANT ALL ON TABLE datomic_kvs TO :"postgres_username";
GRANT ALL ON TABLE datomic_kvs TO public;
