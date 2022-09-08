# Kubeflow Notebook Images for ppc64le

Notebook images for ppc64le (IBM Power processor architecture) compliant with [Kubeflow Notebooks](https://www.kubeflow.org/docs/components/notebooks/).
Images are inspired by [Jupyter's Docker-Stacks](https://github.com/jupyter/docker-stacks) and add Elyra, Huggingface Datasets, and Kubeflow features.

### Features
- multiarch support (ppc64le & x86)
- Jupyter Lab incl. LaTeX support
- TensorFlow / PyTorch
- Kubeflow pipelines SDK
- [Elyra](https://github.com/elyra-ai/elyra) integrated in Jupyter Lab
- Integrated catalog of reusable Kubeflow components
- Package management via [Mamba](https://github.com/mamba-org/mamba)
- Based on [AlmaLinux](https://almalinux.org) and buildable with [UBI](https://developers.redhat.com/products/rhel/ubi)
- Fully OpenShift-compliant (rootless support), kudos to [Graham Dumpleton](https://www.openshift.com/blog/jupyter-on-openshift-part-6-running-as-an-assigned-user-id)
- [BuildX](https://docs.docker.com/build/buildx/) ready

### Pre-Build Images
Go to my kubeflow-notebook-image repository at [IBM's quay.io page](https://quay.io/repository/ibm/kubeflow-notebook-image-ppc64le?tab=tags).

### Building Images

#### Prerequisites
1. Install podman (`yum install docker -y`) or docker (see [OpenPOWER@UNICAMP guide](https://openpower.ic.unicamp.br/post/installing-docker-from-repository/)).
2. `sudo systemctl enable --now docker`
3. Enable [BuildX](https://docs.docker.com/build/buildx/) via `docker buildx install`

#### Configuration
```
git clone https://github.com/lehrig/kubeflow-ppc64le-notebook-images
cd kubeflow-ppc64le-notebook-images

export ELYRA_VERSION=3.11.1
export PYTHON_VERSION=3.8
export TENSORFLOW_VERSION=2.8.1
export SUPPORT_GPU=true
export MINOR_RELEASE=0

export IMAGE=quay.io/ibm/kubeflow-notebook-image-ppc64le
export TAG=elyra${ELYRA_VERSION}-py${PYTHON_VERSION}-tf${TENSORFLOW_VERSION}-v${MINOR_RELEASE}
export TARGET=$IMAGE:$TAG
```

#### Option (a): Podman
```
podman build --format docker --build-arg NB_GID=0 --build-arg ELYRA_VERSION=$ELYRA_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg TENSORFLOW_VERSION=$TENSORFLOW_VERSION --build-arg SUPPORT_GPU=$SUPPORT_GPU -t $TARGET -f Dockerfile --platform linux/amd64,linux/ppc64le --push .
```

#### Option (b): Docker
```
docker build --build-arg NB_GID=0 --build-arg ELYRA_VERSION=$ELYRA_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg TENSORFLOW_VERSION=$TENSORFLOW_VERSION --build-arg SUPPORT_GPU=$SUPPORT_GPU -t $TARGET -f Dockerfile --platform linux/amd64,linux/ppc64le --push .
```
