#!/bin/bash

# Check if app name is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <app_name>"
  exit 1
fi

APP_NAME=$1
BASE_DIR="base/$APP_NAME"
OVERLAY_STAGING="overlays/staging/$APP_NAME"
OVERLAY_PRODUCTION="overlays/production/$APP_NAME"

# Create base directory
mkdir -p $BASE_DIR

# Generate base ConfigMap
cat <<EOF > $BASE_DIR/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: $APP_NAME-config
  namespace: default
data:
  config.yaml: |
    # Your config here
EOF

# Generate base Deployment
cat <<EOF > $BASE_DIR/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $APP_NAME
  template:
    metadata:
      labels:
        app: $APP_NAME
    spec:
      containers:
      - name: $APP_NAME
        image: your-registry/$APP_NAME:latest
        env:
        - name: CONFIG_PATH
          value: /config/config.yaml
        volumeMounts:
        - name: config-volume
          mountPath: /config
      volumes:
      - name: config-volume
        configMap:
          name: $APP_NAME-config
EOF

# Generate base Service
cat <<EOF > $BASE_DIR/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: $APP_NAME
  namespace: default
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: $APP_NAME
EOF

# Create overlays directories
mkdir -p $OVERLAY_STAGING $OVERLAY_PRODUCTION

# Copy base files to overlays
cp $BASE_DIR/* $OVERLAY_STAGING
cp $BASE_DIR/* $OVERLAY_PRODUCTION

echo "Application $APP_NAME setup completed in Kustomize."
