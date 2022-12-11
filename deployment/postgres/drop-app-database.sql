--
-- Template script to drop an application user and database in a shared PostgreSQL
-- database cluster.
--
-- Needs to be executed with DBA priviledges
--
-- Expects these env variables replaced:
--
-- - POSTGRES_APP_NAME
--

\echo ''
\echo '------------------'
\echo 'Dropping the ${POSTGRES_APP_NAME} database in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

-- Stop new connections. Superusers still can connect!
ALTER DATABASE ${POSTGRES_APP_NAME} CONNECTION LIMIT 0;

-- Force disconnection of all clients connected to this database, using pg_terminate_backend.
SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
 WHERE datname = '${POSTGRES_APP_NAME}';

DROP DATABASE ${POSTGRES_APP_NAME};
DROP USER ${POSTGRES_APP_NAME};

\echo '------------------'
\echo ''