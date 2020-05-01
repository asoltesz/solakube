--
-- Script to create the NextCloud user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Creating the NextCloud database in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

CREATE USER nextcloud PASSWORD '${NEXTCLOUD_DB_PASSWORD}';
CREATE DATABASE nextcloud;

\connect nextcloud;

GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;

\echo '------------------'
\echo ''