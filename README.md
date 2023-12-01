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
1. Install docker (see [OpenPOWER@UNICAMP guide](https://openpower.ic.unicamp.br/post/installing-docker-from-repository/)):
```
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install docker-ce docker-ce-cli -y
sudo systemctl enable --now docker
```
2. Configure a [BuildX](https://docs.docker.com/build/buildx/) builder for multi-arch builds.
On x86, just continue with the next step.  
On ppc64le, do the following:
```
mkdir -p ~/.docker/cli-plugins
TARGETARCH=$(uname -m)
OS_ARCH=${TARGETARCH/x86_64/amd64}

wget https://github.com/docker/buildx/releases/download/v0.9.1/buildx-v0.9.1.linux-${OS_ARCH} -O ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx 

docker run --rm --privileged tonistiigi/binfmt:latest --install all
```
Additionally, due to https://github.com/tonistiigi/binfmt/issues/118, you need to pass a Ubuntu-based base root image as build argument to the build (e.g., add this to the build command `--build-arg ROOT_CONTAINER=ubuntu:22.04`)

3. Create, initialize, and use your multi-arch builder:
```
docker buildx create --name mybuilder --use --bootstrap
docker buildx ls
``` 
4. Optional: enable [BuildX](https://docs.docker.com/build/buildx/) by default via `docker buildx install`

#### Configuration
```
git clone https://github.com/lehrig/kubeflow-ppc64le-notebook-images
cd kubeflow-ppc64le-notebook-images

export CUDA_VERSION=11.8.0
export ELYRA_VERSION=3.15.0
export MINOR_RELEASE=3
export PYTHON_VERSION=3.9
export PYTORCH_VERSION=2.0.1
export SUPPORT_GPU=true
export TENSORFLOW_VERSION=2.12.0

export IMAGE=quay.io/ibm/kubeflow-notebook-image-ppc64le
export TAG=elyra${ELYRA_VERSION}-py${PYTHON_VERSION}-tf${TENSORFLOW_VERSION}-pt${PYTORCH_VERSION}-v${MINOR_RELEASE}
export TARGET=$IMAGE:$TAG
```

#### Docker Build
```
docker buildx build --build-arg NB_GID=0 --build-arg CUDA_VERSION=$CUDA_VERSION --build-arg ELYRA_VERSION=$ELYRA_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg PYTORCH_VERSION=$PYTORCH_VERSION --build-arg SUPPORT_GPU=$SUPPORT_GPU --build-arg TENSORFLOW_VERSION=$TENSORFLOW_VERSION -t $TARGET -f Dockerfile --platform linux/amd64,linux/ppc64le --push .
```

#### Optional: Split build & push
Some environments might have a slow upstream, where it makes sense to split the build and the push parts of the build (see https://github.com/docker/buildx/issues/1315).

For building into the cache:
```
docker buildx build --build-arg NB_GID=0 --build-arg CUDA_VERSION=$CUDA_VERSION --build-arg ELYRA_VERSION=$ELYRA_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg PYTORCH_VERSION=$PYTORCH_VERSION --build-arg SUPPORT_GPU=$SUPPORT_GPU --build-arg TENSORFLOW_VERSION=$TENSORFLOW_VERSION -t $TARGET -f Dockerfile --platform linux/amd64,linux/ppc64le --cache-to=type=local,dest=cache,mode=max .
```

For pushing from cache to your image registry, add to the docker/podman command:
```
docker buildx build --build-arg NB_GID=0 --build-arg CUDA_VERSION=$CUDA_VERSION --build-arg ELYRA_VERSION=$ELYRA_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg PYTORCH_VERSION=$PYTORCH_VERSION --build-arg SUPPORT_GPU=$SUPPORT_GPU --build-arg TENSORFLOW_VERSION=$TENSORFLOW_VERSION -t $TARGET -f Dockerfile --platform linux/amd64,linux/ppc64le --push --cache-from=type=local,src=cache .
```

### Testing Mamba Installations
1. Create an empty mamba environment, for example, by connecting into a mamba-enabled container:
```
docker run -it quay.io/ibm/kubeflow-notebook-image-ppc64le:latest /bin/bash
```
...and by initializing an empty environment:
```
mamba create -n myenv
mamba init
/bin/bash
mamba activate myenv
```
2. Experiment with your install configuration until stable, for example:
```
CONDA_OVERRIDE_CUDA="11.4.4" mamba install -c https://ftp.osuosl.org/pub/open-ce/current/ -c main --override-channels python=3.9 pytorch=1.12.1 tensorflow=2.9.2 horovod 'huggingface::datasets>=2.1.0' opencv blas=*=openblas jupyterhub jupyterlab conda mamba pip 'conda-forge::nb_black' 'conda-forge::nodejs>=12.0.0' boto3 brotli dm-tree etils numpy orc pandas pillow transformers 'pynacl' 'regex' 'ujson' altair beautifulsoup4 bokeh bottleneck cloudpickle cython dask dill h5py ipympl ipywidgets matplotlib-base numba numexpr patsy protobuf pytables scikit-image scikit-learn scipy seaborn sqlalchemy statsmodels sympy widgetsnbextension xlrd tensorboard tensorflow-addons tensorflow-datasets tensorflow-hub tensorflow-model-optimization tensorflow-probability tensorflow-text torchvision tf2onnx onnx onnxruntime kedro py-xgboost matplotlib
```
