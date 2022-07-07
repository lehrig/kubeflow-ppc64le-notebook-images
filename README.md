# Kubeflow Notebook Images for ppc64le

Notebook images for ppc64le (IBM Power processor architecture) compliant with [Kubeflow Notebooks](https://www.kubeflow.org/docs/components/notebooks/).
Images are based on [Jupyter's Docker-Stacks](https://github.com/jupyter/docker-stacks) with a base (+ Elyra, Huggingface Datasets) > minimal > SciPy > TensorFlow/PyTorch > Kubeflow stack.

### Features
- ppc64le architecture support
- Jupyter Lab incl. LaTeX support
- TensorFlow / PyTorch
- Kubeflow pipelines SDK
- [Elyra](https://github.com/elyra-ai/elyra) integrated in Jupyter Lab
- Integrated catalog of reusable Kubeflow components
- Package management via [Mamba](https://github.com/mamba-org/mamba)
- Fully OpenShift-compliant (rootless support), kudos to [Graham Dumpleton](https://www.openshift.com/blog/jupyter-on-openshift-part-6-running-as-an-assigned-user-id)

### Pre-Build Images
Go to my kubeflow-notebook-image repository at [IBM's quay.io page](https://quay.io/repository/ibm/kubeflow-notebook-image-ppc64le?tab=tags).

### Building Images

#### Prerequisites
1. Install podman (`yum install docker -y`) or docker (see [OpenPOWER@UNICAMP guide](https://openpower.ic.unicamp.br/post/installing-docker-from-repository/)).
2. `sudo systemctl enable --now docker`

#### Configuration
```
git clone https://github.com/lehrig/kubeflow-ppc64le-notebook-images
cd kubeflow-ppc64le-notebook-images

export ELYRA_VERSION=3.8.0
export PYTHON_VERSION=3.8
export TENSORFLOW_VERSION=2.8.0
export SUPPORT_GPU=true

export IMAGE=quay.io/ibm/kubeflow-notebook-image-ppc64le
export TAG=elyra${ELYRA_VERSION}-py${PYTHON_VERSION}

export BASE_IMAGE=$IMAGE:$TAG-base
export MINIMAL_IMAGE=$IMAGE:$TAG-min
export SCIPY_IMAGE=$IMAGE:$TAG-scipy
export TF_CPU_IMAGE=$IMAGE:$TAG-tensorflow-cpu${TENSORFLOW_VERSION}
export TF_GPU_IMAGE=$IMAGE:$TAG-tensorflow-gpu${TENSORFLOW_VERSION}
```

Then select one of the latter environment variables as ```$TARGET``` and the appropriate Docker file as ```$TARGET_DOCKER_FILE```.
Example:
```
export TARGET=$BASE_IMAGE
export TARGET_DOCKER_FILE=Dockerfile.base
```


#### Option (a): Podman
```
podman build --format docker --squash --build-arg NB_GID=0 --build-arg ELYRA_VERSION=$ELYRA_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg TENSORFLOW_VERSION=$TENSORFLOW_VERSION --build-arg SUPPORT_GPU=$SUPPORT_GPU -t $TARGET -f $TARGET_DOCKER_FILE .
```

#### Option (b): Docker
```
docker build --squash --build-arg NB_GID=0 --build-arg ELYRA_VERSION=$ELYRA_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg TENSORFLOW_VERSION=$TENSORFLOW_VERSION --build-arg SUPPORT_GPU=$SUPPORT_GPU -t $TARGET -f $TARGET_DOCKER_FILE .
```
