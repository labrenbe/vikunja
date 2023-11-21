#!/bin/sh
# OIDC config for vikunja can only be supplied with a config file and not by using envs.
# In a production environment this issue might be addressed by building a custom container image with most of the config and injecting the client secret from a kubernetes secret at runtime.
envsubst < ./bootstrap/vikunja-config.yaml > /tmp/vikunja-config.yaml
kubectl create secret generic vikunja-config -n vikunja --from-file=config.yaml=/tmp/vikunja-config.yaml
rm /tmp/vikunja-config.yaml
