# Kubeflow Notebook Images for ppc64le

Notebook images for ppc64le (IBM Power processor architecture) compliant with [Kubeflow Notebook Server](https://www.kubeflow.org/docs/notebooks/).
Images are based on [Jupyter's Docker-Stacks](https://github.com/jupyter/docker-stacks) with a base > minimal > SciPy > TensorFlow > Kubeflow/Elyra stack.

### Features
- ppc64le architecture support
- Jupyter Lab incl. LaTeX support
- TensorFlow / PyTorch
- Kubeflow pipelines SDK
- [Elyra](https://github.com/elyra-ai/elyra) integrated in Jupyter Lab
- Package management via [Conda](https://docs.conda.io)
- Fully OpenShift-compliant (rootless support), kudos to [Graham Dumpleton](https://www.openshift.com/blog/jupyter-on-openshift-part-6-running-as-an-assigned-user-id)

### Pre-Build Images
Go to my kubeflow-images repository at [IBM's quay.io page](https://quay.io/repository/ibm/kubeflow-notebook-image-ppc64le?tab=tags).

Kubeflow/Elyra images:
- Python v3.6 / TensorFlow v1.15.4 / CPU / Kubeflow v1.2.0 / JupyterLab 3.0.7 / Elyra v2.0.1: quay.io/ibm/kubeflow-notebook-image-ppc64le:tensorflow-1.15.4-cpu-py3.6
- Python v3.8 / TensorFlow v2.4.2 / CPU / Kubeflow v1.3.0 / JupyterLab 3.1.4 / Elyra v3.0.0: quay.io/ibm/kubeflow-notebook-image-ppc64le:tensorflow-2.4.2-cpu-py3.8
- Python v3.8 / TensorFlow v2.4.2 / GPU / Kubeflow v1.3.0 / JupyterLab 3.1.4 / Elyra v3.0.0: quay.io/ibm/kubeflow-notebook-image-ppc64le:tensorflow-2.4.2-gpu-py3.8

### Building Images

#### Prerequisites
1. Install podman (`yum install docker -y`) or docker (see [OpenPOWER@UNICAMP guide](https://openpower.ic.unicamp.br/post/installing-docker-from-repository/)).
2. `sudo systemctl enable --now docker`

#### Configuration
```
git clone https://github.com/lehrig/kubeflow-ppc64le-images
cd kubeflow-ppc64le-images

export PYTHON_VERSION=3.8
export TENSORFLOW_VERSION=2.4.2

export IMAGE=quay.io/ibm/kubeflow-notebook-image-ppc64le
export BASE_IMAGE=$IMAGE:base-py$PYTHON_VERSION
export MINIMAL_IMAGE=$IMAGE:minimal-py$PYTHON_VERSION
export SCIPY_IMAGE=$IMAGE:scipy-py$PYTHON_VERSION
export TF_CPU_IMAGE=$IMAGE:tensorflow-$TENSORFLOW_VERSION-cpu-py$PYTHON_VERSION
export TF_GPU_IMAGE=$IMAGE:tensorflow-$TENSORFLOW_VERSION-gpu-py$PYTHON_VERSION
```

#### Option (a): Podman / Single-Step Images (smaller file size)
```
podman build --format docker NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $TF_CPU_IMAGE -f Dockerfile.all-in-one-cpu .
podman build --format docker NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $TF_GPU_IMAGE -f Dockerfile.all-in-one-gpu .
```

#### Option (b): Docker / Single-Step Images (smaller file size)
```
docker build --build-arg NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $TF_CPU_IMAGE -f Dockerfile.all-in-one-cpu .
docker build --build-arg NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $TF_GPU_IMAGE -f Dockerfile.all-in-one-gpu .
```

#### Option (c): Podman / Multi-Step Images (larger file size but good for debugging)
```
podman build --format docker --build-arg NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $BASE_IMAGE -f Dockerfile.base .
podman build --format docker --build-arg BASE_CONTAINER=$BASE_IMAGE -t $MINIMAL_IMAGE -f Dockerfile.minimal .
podman build --format docker --build-arg BASE_CONTAINER=$MINIMAL_IMAGE -t $SCIPY_IMAGE -f Dockerfile.scipy .
podman build --format docker --build-arg BASE_CONTAINER=$SCIPY_IMAGE -t $TF_CPU_IMAGE -f Dockerfile.tensorflow-cpu .
podman build --format docker --build-arg BASE_CONTAINER=$SCIPY_IMAGE -t $TF_GPU_IMAGE -f Dockerfile.tensorflow-gpu .
```

#### Option (d): Docker / Multi-Step Images (larger file size but good for debugging)
```
docker build --build-arg NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $BASE_IMAGE -f Dockerfile.base .
docker build --build-arg BASE_CONTAINER=$BASE_IMAGE -t $MINIMAL_IMAGE -f Dockerfile.minimal .
docker build --build-arg BASE_CONTAINER=$MINIMAL_IMAGE -t $SCIPY_IMAGE -f Dockerfile.scipy .
docker build --build-arg BASE_CONTAINER=$SCIPY_IMAGE -t $TF_CPU_IMAGE -f Dockerfile.tensorflow-cpu .
docker build --build-arg BASE_CONTAINER=$SCIPY_IMAGE -t $TF_GPU_IMAGE -f Dockerfile.tensorflow-gpu .
```
