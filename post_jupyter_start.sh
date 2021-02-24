#!/bin/bash

sleep 10

# Elyra Kubeflow runtime: if no runtime is installed, install default runtime
if [[ "$(elyra-metadata list runtimes | grep -i json | wc -l)" != "1" ]]; then
  export HOST=$(cat /etc/resolv.conf | grep search | awk '{ print $NF }')
  export API_ENDPOINT=http://istio-ingressgateway-istio-system.apps.$HOST/pipeline
  export COS_ENDPOINT=http://minio-service-kubeflow.apps.$HOST

  elyra-metadata install runtimes \
       --display_name="DEV Runtime - Kubeflow Pipelines" \
       --api_endpoint=$API_ENDPOINT \
       --engine=Argo \
       --cos_endpoint=$COS_ENDPOINT \
       --cos_username=minio \
       --cos_password=minio123 \
       --cos_bucket=kf-pipelines-dev \
       --tags="['kfp', 'v1.2.0', 'dev']"
fi
