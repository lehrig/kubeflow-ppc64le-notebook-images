# kubeflow-ppc64le-images

### Building Images

```
git clone https://github.com/lehrig/kubeflow-ppc64le-images
cd kubeflow-ppc64le-images

export PYTHON_VERSION=3.6
export TENSORFLOW_VERSION=1.15.0

export TAG=v1.2.0.ppc64le
export BASE_IMAGE=lehrig/base-py$PYTHON_VERSION-notebook:$TAG
export IMAGE=lehrig/tensorflow-$TENSORFLOW_VERSION-cpu-py$PYTHON_VERSION-notebook:$TAG

podman build --build-arg NB_GID=0 --build-arg PYTHON_VERSION=$PYTHON_VERSION -t $BASE_IMAGE -f Dockerfile.base .
podman build --build-arg BASE_CONTAINER=$BASE_IMAGE -t $IMAGE -f Dockerfile.tensorflow-1.15.0-cpu-py36 .
```
