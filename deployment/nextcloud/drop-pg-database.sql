--
-- Script to drop the NextCloud user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Dropping the NextCloud database (${NEXTCLOUD_APP_NAME}) in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

DROP DATABASE ${NEXTCLOUD_APP_NAME};
DROP USER ${NEXTCLOUD_APP_NAME};

\echo '------------------'
\echo ''