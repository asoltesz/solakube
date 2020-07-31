--
-- Script to drop the Jcr user and database in a PostgreSQL
-- database cluster.
--
-- Needs to be executed by DBA priviledges
--

\echo ''
\echo '------------------'
\echo 'Dropping the Jcr database (${JCR_APP_NAME}) in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

-- Stop new connections. Superusers still can connect!
ALTER DATABASE ${JCR_APP_NAME} CONNECTION LIMIT 0;

-- Force disconnection of all clients connected to this database, using pg_terminate_backend.
SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
 WHERE datname = '${JCR_APP_NAME}';

DROP DATABASE ${JCR_APP_NAME};
DROP USER ${JCR_APP_NAME};

\echo '------------------'
\echo ''