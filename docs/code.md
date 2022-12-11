# Collabora CODE Document Server

Standalone version of the Collabora CODE Document Server that allows for integrated ODF / Microsoft Office document editing with Nextcloud and other groupware servers.

WARNING: This currently isn't useful, only provided in the hope that its issues can be solved with configuration (please contribute back if you do that). See [Problems](#Problems).

NOTE: The internal CODE server of NextCloud is operational, see the [Nextcloud](nextcloud.md) docs. That is less ideal from the separation/scheduling/scaling point of view but works for small installations.
  
# Configuration

## CODE_VERSION

The version of the Docker image to use.

Optional, defaults to "6.4.0.14"

## CODE_DOMAIN

The domain of the CODE server. 

Optional, defaults to "${CLUSTER_FQN}" (e.g.: andromeda.example.com)

NOTE: SolaKube will auto-escape it.

## CODE_SERVER

The host/server name of the CODE server. 

Optional, defaults to "${CODE_APP_NAME}.${CLUSTER_FQN}" (e.g.: code.andromeda.example.com)

NOTE: SolaKube will auto-escape it.

# Problems

## What works

The Document Server correctly starts up and respons with "OK" on its root path.

The Admin page can be used and shows operational status.

The server is forced to work on HTTP in order to allow TLS terminating in the ingress (which is important when we operate it behind a TLS-terminating proxy like the Kubernetes ingress).

NextCloud accepts the document server as operational when you provide it with CODE's external URL (provided by the ingress).  

## What doesn't work

Cannot edit documents from NextCloud. Only an empty screen appears. No error message.

There is an error message on the document server output when the NextCloud settings page tests the service (and accepts as OK) and that refers to denying access to the caller. (NextCloud probably only tests the root path and doesn't check actual editing capability so it mistakenly believes that everything is OK)
