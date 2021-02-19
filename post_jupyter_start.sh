#!/bin/bash

sleep 10

# Elyra Kubeflow runtime: if no runtime is installed, install default runtime
if [[ "$(elyra-metadata list runtimes | grep -i json | wc -l)" != "1" ]]; then
  elyra-metadata install runtimes \
       --display_name="DEV Runtime - Kubeflow Pipelines" \
       --api_endpoint=http://ml-pipeline-ui.kubeflow \
       --engine=Argo \
       --cos_endpoint=http://minio-service.kubeflow:9000 \
       --cos_username=minio \
       --cos_password=minio123 \
       --cos_bucket=kf-pipelines-dev \
       --tags="['kfp', 'v1.2.0', 'dev']"
fi
