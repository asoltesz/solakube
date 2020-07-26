--
-- Script to create the Gitea user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Creating the Gitea database (${GITEA_APP_NAME}) in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

CREATE USER ${GITEA_APP_NAME} PASSWORD '${GITEA_DB_PASSWORD}';
CREATE DATABASE ${GITEA_APP_NAME};

\connect ${GITEA_APP_NAME};

GRANT ALL PRIVILEGES ON DATABASE ${GITEA_APP_NAME} TO ${GITEA_APP_NAME};

\echo '------------------'
\echo ''