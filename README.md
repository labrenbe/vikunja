### Deployment of Vikunja and other components
Vikunja was deployed to GKE in Google Cloud using a managed loadbalancer created by the gce-ingress-controller and Cloud SQL as external postgres database for vikunja and keycloak. All kubernetes resources were deployed using GitOps with ArgoCD to ensure that the state of the cluster always reflects the state of this git repository. This way manual changes to the infrastructure are prevented and intended changes can be reviewed with pull requests and approval workflows.

The Vikunja frontend and backend are deployed using a single opinionated and internal Helm chart. This way only a smaller set of input parameters are exposed which allows an easier deployment in a known environment.

ArgoCD and cert-manager are templated using kustomize because both applications are deployed with default configurations adding only resource requests/limits and fixing a known issue in ArgoCD. Since there is no additional deployment-specific configuration, adding an additional layer of complexity to kubernetes manifests by using Helm as a templating engine seems unnecessary.

Keycloak was deployed using the Bitnami Helm chart because a comprehensive first-party kustomize base is not available and building an own Helm chart seemed like reinventing the wheel. The kubernetes ingress for keycloak was deployed in an additional additional ArgoCD application using static yaml because the chart doesn't allow adding annotations or additional paths to the ingress object.

### How to bootstrap the cluster
- This setup is using an external database provided by Google's Cloud SQL. As a prerequisite, the database has to be set up with a databases and users created for vikunja and keycloak. The Cloud SQL instance has to be reachable from the kubernetes cluster and using private networking. 
- After obtaining a kubeconfig for a newly created GKE cluster using gcloud, kubernetes secrets for database connection details and the initial keycloak admin password need to be created.
- In the next step ArgoCD is deployed by applying it's kustomization and an root application for ArgoCD which deploy all further applications (app-of-apps). ArgoCD will then start managing itself.
- These steps are automated by _bootstrap.sh_ and require certain environment variables to be set.

### Reasons to use Cloud SQL over self-hosting the database
- Many maintenance tasks like backups, security patches and version upgrades are done by Google.
- An HA-setup with automated failover to another availability zone is easy to set up.
- Desaster recovery is likely  to be more reliable than a self-hosted solution.
- Consuming a managed service frees up engineering ressources to focus on other tasks.
- The additional flexibility of self-hosting the database is not a requirement for vikunja or keycloak, e.g. using a very specific version of postgres.

### Monitoring / Troubleshooting
For monitoring cluster and application health features built into GKE based on Prometheus & Cloud Logging can be used.

To troubleshoot issue directly in the kubernetes cluster using the cli tool k9s is recommended.

### IAM with Keycloak
A private OIDC client for Vikunja was created in a dedicated realm in keycloak. The vikunja backend is configured to use keycloak as an OIDC provider by mounting a configuration file through a kubernetes secret. This method was chosen because configuring authentication for vikunja using environment variables is currently not supported. The kubernetes secret is created outside of ArgoCD to not leak the OIDC client secret through git. _create-vikunja-config.sh_ can be used to automate this task.

Unfortunately there is still a bug in the OIDC flow preventing user from completing the flow. The Vikunja backend is unable to exchange the authorization code returned by keycloak after a user's successful authentication for an access token. It seems the underlying issue might be related to the oauth2 library used by Vikunja making multiple requests to keycloak using the same authorization code, but no definite root cause was identified.
