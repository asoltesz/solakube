--
-- Script to create the Redmine user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Creating the Redmine database (${REDMINE_APP_NAME}) in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

CREATE USER ${REDMINE_APP_NAME} PASSWORD '${REDMINE_DB_PASSWORD}';
CREATE DATABASE ${REDMINE_APP_NAME};

\connect ${REDMINE_APP_NAME};

GRANT ALL PRIVILEGES ON DATABASE ${REDMINE_APP_NAME} TO ${REDMINE_APP_NAME};

\echo '------------------'
\echo ''