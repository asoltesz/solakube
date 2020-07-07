--
-- Script to create the NextCloud user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Creating the NextCloud database (${NEXTCLOUD_APP_NAME}) in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

CREATE USER ${NEXTCLOUD_APP_NAME} PASSWORD '${NEXTCLOUD_DB_PASSWORD}';
CREATE DATABASE ${NEXTCLOUD_APP_NAME};

\connect ${NEXTCLOUD_APP_NAME};

GRANT ALL PRIVILEGES ON DATABASE ${NEXTCLOUD_APP_NAME} TO ${NEXTCLOUD_APP_NAME};

\echo '------------------'
\echo ''