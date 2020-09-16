--
-- Template script to create an application user and database in a shared
-- PostgreSQL database cluster.
--
-- Needs to be executed with DBA priviledges
--
-- Expected template variables:
--
-- - POSTGRES_APP_NAME
--   This will be the name of the database and the name of
--   the user that can access the database.
--
-- - POSTGRES_APP_DB_PASSWORD
--   The password belonging to the application user
--

\echo ''
\echo '------------------'
\echo 'Creating the ${POSTGRES_APP_NAME} Postgres database in the PostgreSQL db cluster'
\echo '------------------'
\echo ''

CREATE USER ${POSTGRES_APP_NAME} PASSWORD '${POSTGRES_APP_DB_PASSWORD}';

SELECT 'CREATE DATABASE ${POSTGRES_APP_NAME}'
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${POSTGRES_APP_NAME}')\gexec

\connect ${POSTGRES_APP_NAME};

GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_APP_NAME} TO ${POSTGRES_APP_NAME};

\echo '------------------'
\echo ''