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

# Elyra Kubeflow runtime images: rewire images for ppc64le
elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="anaconda" \
       --display_name="Miniforge 4.10.3 with Python 3.8" \
       --description="Python v3.8 / Elyra v3.0.0 / Conda v4.10.3" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-anaconda4.10.3" \
       --tags="['anaconda']" \
       --replace
       
elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="pandas" \
       --display_name="Pandas 1.1.1" \
       --description="Python v3.8 / Elyra v3.0.0 / Conda v4.10.3 / Pandas 1.1.1" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-pandas1.1.1" \
       --tags="['pandas']" \
       --replace
 
elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="pytorch-devel" \
       --display_name="Pytorch 1.4 with CUDA-devel" \
       --description="PyTorch 1.4 (with GPU support)" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-pytorch-devel1.4" \
       --tags="['gpu', 'pytorch']" \
       --replace

elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="pytorch-runtime" \
       --display_name="Pytorch 1.4 with CUDA-runtime" \
       --description="PyTorch 1.4 (with GPU support)" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-pytorch-runtime1.4" \
       --tags="['gpu', 'pytorch']" \
       --replace
 
elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="r" \
       --display_name="R Script" \
       --description="R Script" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-r4" \
       --tags="['R']" \
       --replace

elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="tensorflow_2x_gpu_py3" \
       --display_name="Tensorflow 2.3.1 with GPU" \
       --description="TensorFlow 2.3 (with GPU support)" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-tensorflow2.3.1" \
       --tags="['gpu', 'tensorflow']" \
       --replace

elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="tensorflow_2x_py3" \
       --display_name="Tensorflow 2.3.1" \
       --description="TensorFlow 2.3" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-tensorflow-cpu2.3.1" \
       --tags="['tensorflow']" \
       --replace

elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="tensorflow_gpu_py3" \
       --display_name="Tensorflow 1.15.2 with GPU" \
       --description="TensorFlow 1.15 (with GPU support)" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-tensorflow1.15.2" \
       --tags="['gpu', 'tensorflow']" \
       --replace

elyra-metadata install runtime-images --schema_name=runtime-image \
       --name="tensorflow_py3" \
       --display_name="Tensorflow 1.15.2" \
       --description="TensorFlow 1.15" \
       --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-tensorflow-cpu1.15.2" \
       --tags="['tensorflow']" \
       --replace
