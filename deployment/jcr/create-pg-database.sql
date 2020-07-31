--
-- Script to create the Jcr user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Creating the Jcr database (${JCR_APP_NAME}) in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

CREATE USER ${JCR_APP_NAME} PASSWORD '${JCR_DB_PASSWORD}';
CREATE DATABASE ${JCR_APP_NAME};

\connect ${JCR_APP_NAME};

GRANT ALL PRIVILEGES ON DATABASE ${JCR_APP_NAME} TO ${JCR_APP_NAME};

\echo '------------------'
\echo ''