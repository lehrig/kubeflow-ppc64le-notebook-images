# Kubeflow Notebook Images for ppc64le

Notebook images for ppc64le (IBM Power processor architecture) compliant with [Kubeflow Notebook Server](https://www.kubeflow.org/docs/notebooks/).

### Features
- Jupyter Lab incl. LaTeX support
- TensorFlow / PyTorch
- Kubeflow pipelines SDK
- [Elyra](https://github.com/elyra-ai/elyra) integrated in Jupyter Lab
- [Kale](https://github.com/kubeflow-kale/kale) integrated in Jupyter Lab
- Package management via [Conda](https://docs.conda.io)
- Fully OpenShift-compliant (rootless support), kudos to [Graham Dumpleton](https://www.openshift.com/blog/jupyter-on-openshift-part-6-running-as-an-assigned-user-id)

### Pre-Build Images
Go to my [Docker.io page](https://hub.docker.com/u/lehrig) (includes Notebook and general Kubeflow images for ppc64le).

Notebook images:
- [Kubeflow v1.2.0 / TensorFlow v1.15.4 / Jupyter Lab 3.0.7 / Elyra v2.0.1 / CPU / Python v3.6](https://hub.docker.com/r/lehrig/tensorflow-1.15.4-cpu-py3.6-notebook)

### Building Images

```
git clone https://github.com/lehrig/kubeflow-ppc64le-images
cd kubeflow-ppc64le-images

export PYTHON_VERSION=3.6
export TENSORFLOW_VERSION=1.15.4

export TAG=v1.2.0.ppc64le
export BASE_IMAGE=lehrig/base-py$PYTHON_VERSION-notebook:$TAG
export IMAGE=lehrig/tensorflow-$TENSORFLOW_VERSION-cpu-py$PYTHON_VERSION-notebook:$TAG

podman build --build-arg NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $BASE_IMAGE -f Dockerfile.base .
podman build --build-arg BASE_CONTAINER=$BASE_IMAGE -t $IMAGE -f Dockerfile.tensorflow-cpu .
```
