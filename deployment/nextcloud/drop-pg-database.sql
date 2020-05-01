--
-- Script to drop the NextCloud user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Dropping the NextCloud database in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

DROP DATABASE nextcloud;
DROP USER nextcloud;

\echo '------------------'
\echo ''