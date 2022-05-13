#!/bin/bash

# if no components are installed, this is a first-time run -> configure Elyra
if [[ $(elyra-metadata list component-catalogs) == "No metadata instances found for component-catalogs" ]] 
then  
    ############################################################
    # Elyra runtime images: rewire images for ppc64le
    elyra-metadata update runtime-images \
      --name="anaconda" \
      --display_name="Miniforge 4.10.3 with Python 3.8" \
      --description="Python v3.8 / Conda v4.10.3" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:elyra3.6.0-py3.8-anaconda4.10.3" \
      --tags="['anaconda']"
       
    elyra-metadata update runtime-images \
      --name="pandas" \
      --display_name="Pandas 1.4.1" \
      --description="Python v3.8 / Conda v4.10.3 / Pandas 1.4.1" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:elyra3.6.0-py3.8-pandas1.4.1" \
      --tags="['pandas']"
 
    elyra-metadata update runtime-images \
      --name="pytorch-devel" \
      --display_name="Pytorch 1.4 with CUDA-devel" \
      --description="PyTorch 1.4 (with GPU support)" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:elyra3.6.0-py3.8-pytorch-devel1.4" \
      --tags="['gpu', 'pytorch']"

    elyra-metadata update runtime-images \
      --name="pytorch-runtime" \
      --display_name="Pytorch 1.4 with CUDA-runtime" \
      --description="PyTorch 1.4 (with GPU support)" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:elyra3.6.0-py3.8-pytorch-runtime1.4" \
      --tags="['gpu', 'pytorch']"
 
    elyra-metadata update runtime-images \
      --name="r" \
      --display_name="R Script" \
      --description="R Script" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:elyra3.6.0-py3.8-r4" \
      --tags="['R']"

    elyra-metadata update runtime-images \
      --name="tensorflow_2x_gpu_py3" \
      --display_name="Tensorflow 2.7.0 with GPU" \
      --description="TensorFlow 2.7.0 (with GPU support)" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:elyra3.6.0-py3.8-tensorflow2.7.0" \
      --tags="['gpu', 'tensorflow']"

    elyra-metadata update runtime-images \
      --name="tensorflow_2x_py3" \
      --display_name="Tensorflow 2.7.0" \
      --description="TensorFlow 2.7.0" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:elyra3.6.0-py3.8-tensorflow-cpu2.7.0" \
      --tags="['tensorflow']"

    elyra-metadata update runtime-images \
      --name="tensorflow_gpu_py3" \
      --display_name="Tensorflow 1.15.2 with GPU" \
      --description="TensorFlow 1.15 (with GPU support)" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-tensorflow1.15.2" \
      --tags="['gpu', 'tensorflow']"

    elyra-metadata update runtime-images \
      --name="tensorflow_py3" \
      --display_name="Tensorflow 1.15.2" \
      --description="TensorFlow 1.15" \
      --image_name="quay.io/ibm/kubeflow-elyra-runtimes-ppc64le:py3.8-tensorflow-cpu1.15.2" \
      --tags="['tensorflow']"

    ############################################################
    # Custom Kubeflow components
    elyra-metadata create component-catalogs \
      --name="extract" \
      --description="Extract data" \
      --runtime_type="KUBEFLOW_PIPELINES" \
      --display_name="Data Extraction" \
      --categories='["Data Extraction"]' \
      --paths="[ \
        'https://raw.githubusercontent.com/lehrig/kubeflow-ppc64le-components/main/data-extraction/download-and-extract-from-url/component.yaml'
        ]" \
      --schema_name="url-catalog"
       
    elyra-metadata create component-catalogs \
      --name="transform" \
      --description="Transform data" \
      --runtime_type="KUBEFLOW_PIPELINES" \
      --display_name="Data Transform" \
      --categories='["Data Transform"]' \
      --paths="[ \
        'https://raw.githubusercontent.com/lehrig/kubeflow-ppc64le-components/main/data-transformation/run-spark-job/component.yaml'
        ]" \
      --schema_name="url-catalog"

    elyra-metadata create component-catalogs \
      --name="build" \
      --description="Build models" \
      --runtime_type="KUBEFLOW_PIPELINES" \
      --display_name="Model Building" \
      --categories='["Model Building"]' \
      --paths="[ \
        'https://raw.githubusercontent.com/lehrig/kubeflow-ppc64le-components/main/model-building/convert-to-onnx/component.yaml', \
        'https://raw.githubusercontent.com/lehrig/kubeflow-ppc64le-components/main/model-building/upload-model/component.yaml'
        ]" \
      --schema_name="url-catalog"

    elyra-metadata create component-catalogs \
      --name="deployment" \
      --description="Deploying models for model serving" \
      --runtime_type="KUBEFLOW_PIPELINES" \
      --display_name="Model Deployment" \
      --categories='["Model Deployment"]' \
      --paths="[ \
        'https://raw.githubusercontent.com/lehrig/kubeflow-ppc64le-components/main/model-deployment/deploy-model-with-kserve/component.yaml', \
        'https://raw.githubusercontent.com/lehrig/kubeflow-ppc64le-components/main/model-deployment/deploy-model-with-tfserving/component.yaml', \
	'https://raw.githubusercontent.com/lehrig/kubeflow-ppc64le-components/main/model-deployment/deploy-model-with-triton/component.yaml'
	]" \
      --schema_name="url-catalog"

    ############################################################
    # Default Kubeflow Runtime
    
    export KFP_HOST=$(getent hosts kubeflow.apps | awk '{ print $2 }')
    export MINIO_HOST=$(getent hosts minio-service-kubeflow.apps | awk '{ print $2 }')

    export PUBLIC_API_ENDPOINT=http://$KFP_HOST/pipeline
    export COS_ENDPOINT=http://$MINIO_HOST
  
    export USER_NAMESPACE=$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)
    
    elyra-metadata create runtimes \
      --schema_name=kfp \
      --display_name="DEV Runtime - Kubeflow Pipelines" \
      --public_api_endpoint=$PUBLIC_API_ENDPOINT \
      --api_endpoint="http://ml-pipeline.kubeflow.svc.cluster.local:8888/" \
      --user_namespace=$USER_NAMESPACE \
      --auth_type="KUBERNETES_SERVICE_ACCOUNT_TOKEN" \
      --engine=Argo \
      --cos_endpoint=$COS_ENDPOINT \
      --cos_auth_type="USER_CREDENTIALS" \
      --cos_username=minio \
      --cos_password=minio123 \
      --cos_bucket=kf-pipelines-dev \
      --tags="['kfp', 'dev']"
      
    # HotFix for https://github.com/elyra-ai/elyra/issues/2725
    touch /home/jovyan/.local/share/jupyter/metadata/runtimes/hotfix2725.fix
    rm -f /home/jovyan/.local/share/jupyter/metadata/runtimes/hotfix2725.fix
fi
