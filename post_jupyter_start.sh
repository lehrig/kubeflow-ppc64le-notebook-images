#!/bin/bash

sleep 10

# Elyra Kubeflow runtime: if no runtime is installed, install default runtime
if [[ "$(elyra-metadata list runtimes | grep -i json | wc -l)" != "1" ]]; then
  export KFP_HOST=$(getent hosts istio-ingressgateway-istio-system.apps | awk '{ print $2 }')
  export MINIO_HOST=$(getent hosts minio-service-kubeflow.apps | awk '{ print $2 }')

  export API_ENDPOINT=http://$KFP_HOST/pipeline
  export COS_ENDPOINT=http://$MINIO_HOST

  elyra-metadata install runtimes \
       --display_name="DEV Runtime - Kubeflow Pipelines" \
       --api_endpoint=$API_ENDPOINT \
       --engine=Argo \
       --cos_endpoint=$COS_ENDPOINT \
       --cos_username=minio \
       --cos_password=minio123 \
       --cos_bucket=kf-pipelines-dev \
       --tags="['kfp', 'v1.3.0', 'dev']" \
       --schema_name=kfp
fi
