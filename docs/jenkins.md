# Jenkins CI/CD server

Jenkins is a flexible continuous integration (CI) and continuous deployment (CD) server.

SolaKube uses the stable Helm chart of Jenkins with an opinionated setup for:
 - defining agent node templates as Kubernetes pods (with sample templates)
 - defining jobs with a simplified Groovy DSL (with sample jobs)
 - configuring the Mailer system (SMTP notifications)
 - configuration update mechanism
 - backup profile (Velero) for disaster recovery

# Architecture of the Jenkins Deployment

## Configuration As Code (CasC) 

Jenkins configuration is fairly complex and hard to reproduce in most non-trivial installations.

In order to make the Jenkins base config and the job definitions portable, the Jenkins stable Helm chart recommends using the Configuration-As-Code plugin (CasC) and defining all Jenkins settings in text configuration files that are automatically loaded into the Jenkins instance.
 
SolaKube extends this with the Jobs DSL plugin which allows for defining the jobs in a compact and human-readable form (Groovy DSL). Without this, the Helm chart only allows defining the jobs in XML form which is pretty verbose and hard to read.

CasC also allows to place your Jenkins base config & job descriptions under version control (e.g.: via putting the SolaKube project under version control) so that changes can be tracked nicely.

It is possible to use Jenkins without CasC but SolaKube will NOT be able to auto-configure much, and you will need to manually set most things on the Jenkins UI. 

## Build pods and pod templates

On Kubernetes, Jenkins build jobs run in dynamically created build pods (agent nodes, in traditional Jenkins setups) .
 
Build pods can be removed immediately after the job finishes or left there idle for a while in order to allow for faster startup of the next similar job.

Build pods are listed as "Nodes" on the Jenkins UI (build runners).

Different build job types require different pod templates.

Pod templates typically differ in the main container image they use since the build image is specific to the type of build artifacts we want to produce.

For example:
- A Java / Maven based build job will require a Docker image that contains the Java JDK and Maven so that it can compile Java code and package it with Maven into JAR and WAR files.
- An Angular build needs a Docker image that has the necessary NodeJS installation in it which allows building the optimized JS and CSS application files that form the distributable/deployable form of an ANgular app. 

All build pods will automatically contain the Jenkins JNLP agent in a side-container named "jnlp", so that a newly created build pod can connect to the Jenkins instance (pod), receive build instructions and report back results. See the [Jenkins Inbound Agent Docker Image](https://hub.docker.com/r/jenkins/inbound-agent/) for a starting point.

For details, see the "Pod Templates" under the Configuration section.

## References

Further useful information to understand Jenkins on Kubernetes and the Configuration as Code mechanisms: 
- [Jenkins on Kubernetes](https://cloud.google.com/solutions/jenkins-on-kubernetes-engine)
- [Jenkins Helm chart (stable)](https://github.com/helm/charts/tree/master/stable/jenkins)
- The [Jenkins Configuration As Code Plugin (JCasC)](https://www.jenkins.io/projects/jcasc/)
- The [Jenkins Kubernetes Plugin](https://www.jenkins.io/projects/kubernetes/)
- The [Jenkins Job DSL plugin](https://plugins.jenkins.io/job-dsl/)
- Docker in Docker build pods: [Building Docker images inside Kubernetes](https://medium.com/hootsuite-engineering/building-docker-images-inside-kubernetes-42c6af855f25)

# Configuration

## Email notifications (SMTP config)

The Jenkins Mailer plugin makes it possible for Jenkins to send email notifications to people about build jobs (via SMTP). The plugin itself is installed by default in Jenkins.
 
If the SMTP_XXX parameters are defined in SolaKube, the Jenkins Mailer plugin gets automatically configured with the SMTP parameters.

The plugin will work with default settings. For complete configuration, see the plugin documentation and the chart-values-mailer.yaml file.  

Note: Depends on CasC (enabled by default)

## Main Git Access params

With smaller organizations often a single Git host is used (e.g.: a Gitea or Gitlab instance) and a single credential is used to checkout code for Jenkins builds.

For this the following SolaKube variables can be used:

~~~
# The short-name/id of the main Git repo host you will typically check-out
# sources with Jenkins (e.g.: "github" or "internal-gitlab"
export JENKINS_MAIN_GIT_ID="gitea"

# The base URL of the repos on the main repo host
# E.g.: https://github.com
export JENKINS_MAIN_GIT_BASE_URL="https://gitea.example.com"

# The username for the main Git repo host that can be used for Jenkins
# to check out sources for build jobs
export JENKINS_MAIN_GIT_USERNAME="ci"

# The password belonging to the username for the main Git repo host
export JENKINS_MAIN_GIT_PASSWORD="xxxx"

~~~ 

If the main git ID is defined, a Jenkins secret will be automatically defined with the "${JENKINS_MAIN_GIT_USERNAME}-${JENKINS_MAIN_GIT_ID}" id template (e.g.: ci-gitea). This can be referenced in jobs that need to check out code from the Git repository manager/host. 

Note: Depends on CasC (enabled by default)

## Defining the Jobs (in DSL)

The jobs can be defined with Grrovy DSL code with the [Jenkins Jobs DSL plugin](https://plugins.jenkins.io/job-dsl/).

Place the job definitions in the **chart-values-jobs.yaml** file.

The Job DSL API reference can be found [here](https://jenkinsci.github.io/job-dsl-plugin/#).

Note: Depends on CasC (enabled by default)

## Test job for validation

If the SolaKube can deploy a test job to verify the Jenkins installation with running a simple build job that checks out code from a Git checkout and then sends a simple message to the console (bash echo).

For this set the test Git repo path variable:
~~~
#
# The repo path of a test Git repo that can be used for creating a sample
# job for validating the Jenkins installation.
# This will be attached to the main Git repo (JENKINS_MAIN_GIT_BASE_URL)
# to form a full repo URL.
#
# E.g.: my-app/sources.git
#
# If this is provided, a sample Job will be deployed into Jenkins that
# checks out this repository with the main git credentials.
#
export JENKINS_MAIN_GIT_TEST_REPO_PATH="my-app/sources.git"
~~~ 

Note: Depends on CasC (enabled by default)

## Build Pod templates

The **chart-values-agent-pod-templates.yaml** file can be used to define pod templates for different kinds of builds.

~~~
agent:
  podTemplates:
    #
    # Build container for Python 3 applications
    #
    python: |
      - name: python
        label: python
        serviceAccount: jenkins
        containers:
          - name: python
            image: python:3
            command: "/bin/sh -c"
            args: "cat"
            ttyEnabled: true
            privileged: true
            resourceRequestCpu: "400m"
            resourceRequestMemory: "512Mi"
            resourceLimitCpu: "1"
            resourceLimitMemory: "1024Mi"

~~~

### Reusing build pods

It is possible to allow a build pod to be idle for a certain amount of minutes.

In chart-values.yaml:

~~~
# For setting the idle time globally
agent:
    idleMinutes: 10
~~~

In chart-values-pod-templates.yaml, you can configure the idle time for each build-agent type (pod template)

.

## Disabling Configuration-As-Code

Disable the CasC mechanism in chart-values.yaml:

~~~
master:
    ...
    JCasC:
        enabled: false
~~~

NOTES:
- SolaKube will not be able to configure any settings based on CasC.
- Backups are crucial without CasC since all of your settings and jobs will only be defined on the Jenkins persistent storage (see Disaster Recovery section)

## Resource usage

### CPU and memory

The default SolaKube installation limits the Jenkins pod to 512Mb. 

This is suitable for small installations (since builds happen to separate pods anyways) but will likely not enough for larger organizations.

CPU usage is limited to 2 cores (2000m).

Check the memory settings in chart-values.yaml and customize it to your build job loads:

~~~
master:
...
    resources:
        requests:
            cpu: "100m"
            memory: "256Mi"
        limits:
            cpu: "2000m"
            memory: "512Mi"

~~~

In case you want to ensure a certain amount of memory and CPU, raise the "requests" resources as well.

### Persistent disk storage

In case you don't plan to store a lot of build artifacts in Jenkins (e.g.: you also use Nexus or other artifact repo), a limited amount of persistent disk storage may be sufficient.

The SolaKube default is 5 GB but can be set to any size via variables.sh:

~~~
# The size of the persistent storage for the application
export JENKINS_PVC_SIZE="3Gi"
~~~ 


# Deployment

In case the deployment is part of the initial cluster build (sk build), set the appropriate deployer flag before building the cluster:

~~~
export SK_DEPLOY_JENKINS="Y"
~~~

In case of a separate deployment, manually execute the deployer :

~~~
sk deploy jenkins
~~~ 

# Updating the Jenkins Configuration

After the initial deployment, the recommended way of updating the configuration (including the job descriptions) is updating the chart-values files and executing the update with SolaKube:

~~~
sk deploy jenkins update
~~~ 

This will load the updated configuration into Kubernetes ConfigMaps that are the basis of the Jenkins configuration.

The Jenkins pod will automatically notice the configuration change and reload all changes. (The pod itself will not restart for this operation)

# Disaster Recovery

If allowed, SolaKube will deploy a default Velero backup profile which saves all persistent data of Jenkins to the backup storage. Customize the backup [as needed](velero-backups.md).

In case Configuration-As-Code (CasC) is used (the SolaKube default) this will only affect the data of job executions (e.g. console logs) since the configuration (including the jobs) comes from chart-values.yaml files and that can be reloaded into Jenkins any time (see the "Updating the Jenkins Configuration" section).

In case you disable CasC, and change the configuration via the Jenkins UI (e.g. add new job definitions) the backup is crucial since that will contain the job describtions and the base Jenkins configuration.  

