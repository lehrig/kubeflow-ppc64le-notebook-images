# Note - parts of this file are under:
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Options:
# - AlmaLinux (default; e.g., quay.io/almalinux/almalinux:8.6)
# - UBI (ensure active subscriptions at host; e.g., registry.access.redhat.com/ubi8/ubi:8.6)
# - CentOS (e.g., quay.io/centos/centos:stream8)
ARG ROOT_CONTAINER=quay.io/almalinux/almalinux:8.6
FROM $ROOT_CONTAINER
LABEL maintainer="Sebastian Lehrig <sebastian.lehrig1@ibm.com>"

ARG CUDA_VERSION=11.4.4
ARG ELYRA_VERSION=3.14.1
# highest kubeflow-supported release
ARG KUBECTL_VERSION=v1.24.8
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.9
ARG PYTORCH_VERSION=1.12.1
ARG SUPPORT_GPU=true
# Arch is automatically provided by buildx
# See: https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH
ARG TENSORFLOW_VERSION=2.9.2

ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    # Import matplotlib the first time to build the font cache.
    XDG_CACHE_HOME="/home/${NB_USER}/.cache/"
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
# Packages to install
COPY dnf_requirements.txt dnf_requirements.txt
# All root-related
RUN chmod a+rx /usr/local/bin/fix-permissions && \
    # dnf
    # See: https://rpmfusion.org/Configuration
    dnf -y install \
        dnf-plugins-core \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm \
        https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm \
    && \
    # Fix for librose, which needs libffi.so.7
    # --skip-broken ensures that this command does not fail on other archs than ppc64le while avoiding an if statement that breaks docker build caches
    dnf -y --skip-broken install https://rpmfind.net/linux/opensuse/distribution/leap/15.3/repo/oss/ppc64le/libffi7-3.2.1.git259-10.8.ppc64le.rpm && \
    dnf config-manager --set-enabled powertools && \
    dnf makecache --refresh && \
    dnf -y upgrade && \
    dnf -y groupinstall "Development Tools" && \
    dnf -y install $(cat dnf_requirements.txt) && \
    dnf clean all && rm -rf /var/cache/dnf/* && rm -rf /var/cache/yum  && \
    rm -f dnf_requirements.txt && \
    # kubectl
    curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl && \
    chmod +x ./kubectl && \
    cp ./kubectl /usr/local/bin/oc && \
    mv ./kubectl /usr/local/bin/kubectl && \
    # Allow OpenSSH to talk to containers without asking for confirmation
    # by disabling StrictHostKeyChecking.
    # mpi-operator mounts the .ssh folder from a Secret. For that to work, we need
    # to disable UserKnownHostsFile to avoid write permissions.
    # Disabling StrictModes avoids directory and files read permission checks.
    mkdir -p /var/run/sshd && \
    sed -i 's/[ #]\(.*StrictHostKeyChecking \).*/ \1no/g' /etc/ssh/ssh_config && \
    echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config && \
    sed -i 's/#\(StrictModes \).*/\1no/g' /etc/ssh/sshd_config && \
    # nano-tiny
    update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10 && \
    # Enable prompt color in the skeleton .bashrc before creating the default NB_USER
    # hadolint ignore=SC2016
    sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
    echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc && \
    # Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
    # and make sure these dirs are writable by the `users` group.
    echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    groupadd -f --gid 1337 $NB_USER && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    # Cleanup
    fix-permissions "${HOME}" && \
    fix-permissions "${CONDA_DIR}"

ENV LC_ALL=en_US.utf8 \
    LANG=en_US.utf8 \
    LANGUAGE=en_US.utf8

USER ${NB_UID}

COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"

WORKDIR /tmp

# Setup work directory for backward-compatibility
# Download and install Micromamba, and initialize Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba, Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}" && \
    set -x && \
    MICRO_MAMBA_TARGETARCH=$TARGETARCH && \
    if [ "${TARGETARCH}" = "amd64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        MICRO_MAMBA_TARGETARCH="64"; \
    fi && \
    wget -qO /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${MICRO_MAMBA_TARGETARCH}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    if [ "${TARGETARCH}" == "arm" ]; then \
        # Prevent libmamba from sporadically hanging on arm64 under QEMU
        # <https://github.com/mamba-org/mamba/issues/1611>
        # We don't use `micromamba config set` since it instead modifies ~/.condarc.
        echo "extract_threads: 1" >> "${CONDA_DIR}/.condarc"; \
    fi && \
    if [ $SUPPORT_GPU=true ]; then TENSORFLOW="tensorflow" && PYTORCH="pytorch"; else TENSORFLOW="tensorflow-cpu" && PYTORCH="pytorch-cpu"; fi && \
    if [ "${TARGETARCH}" = "ppc64le" ]; then \
        HOROVOD="horovod=0.25.0"; \
    else \
        if [ "${TENSORFLOW_VERSION}" = "2.9.2" ]; then TENSORFLOW_VERSION=2.9.1; fi && \
        HOROVOD='deepmodeling::horovod==0.25.0=horovod-0.25.0-py38h6a4de79_0'; \
    fi && \
    # Install the packages
    # Conda see: https://conda-forge.org/docs/user/tipsandtricks.html#installing-cuda-enabled-packages-like-tensorflow-and-pytorch
    CONDA_OVERRIDE_CUDA=${CUDA_VERSION} ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        # core packages (most dependencies)
        "${HOROVOD}" \
        "${PYTHON_SPECIFIER}" \
        "${PYTORCH}=${PYTORCH_VERSION}" \
        "${TENSORFLOW}=${TENSORFLOW_VERSION}" \
        'blas=*=openblas' \
        'opencv' \
        # 3rd party conda channels (avoid adding such channels as defaults!)
        'conda-forge::nb_black' \
        'conda-forge::nodejs>=12.0.0' \
        'huggingface::datasets>=2.1.0' \
        # package management
        'conda' \
        'mamba' \
        'pip' \
        # jupyter
        # see: https://github.com/jupyter/docker-stacks/blob/main/base-notebook/Dockerfile
        'jupyterhub' \
        'jupyterlab' \
        'notebook' \
        # additional packages (alphabetical order)
        # mainly based on scipy-notebook; extended by some other common packages
        # see: https://github.com/jupyter/docker-stacks/blob/main/scipy-notebook/Dockerfile
        'altair' \
        'arrow' \
        'bcrypt' \
        'beautifulsoup4' \
        'bokeh' \
        'boto3' \
        'bottleneck' \
        'brotli' \
        'cloudpickle' \
        'cython' \
        'dask' \
        'dill' \
        'dm-tree' \
        'etils' \
        'gensim' \
        'h5py' \
        'ipympl'\
        'ipywidgets' \
        'jupyter_enterprise_gateway' \
        'kedro' \
        'matplotlib' \
        'matplotlib-base' \
        'numba' \
        'numexpr' \
        'numpy' \
        'onnx' \
        'onnxruntime' \
        'openmpi' \
        'openpyxl' \
        'orc' \
        'pandas' \
        'patsy' \
        'pillow' \
        'protobuf' \
        'py-xgboost' \
        'pyarrow' \
        'pynacl' \
        'pytables' \
        'regex' \
        'scikit-image' \
        'scikit-learn' \
        'scipy' \
        'seaborn' \
        'sqlalchemy' \
        'statsmodels' \
        'sympy' \
        'tensorboard' \
        'tensorflow-datasets' \
        'tensorflow-hub' \
        'tensorflow-probability' \
        'tf2onnx' \
        'torchvision' \
        'transformers' \
        'ujson' \
        'widgetsnbextension'\
        'xlrd' \
        # ----        
    && \
    mkdir ~/.pip && \
    echo "[global]" >> ~/.pip/pip.conf && \
    echo "extra-index-url = https://repo.fury.io/mgiessing" >> ~/.pip/pip.conf && \
    pip install --prefer-binary --no-cache-dir \
        ##################
        # pip packages
        "elyra==${ELYRA_VERSION}" \
        "librosa" \
        "trino" \
        # Fix for elyra not getting installed due to:
        # Found existing installation: termcolor 1.1.0
        # ERROR: Cannot uninstall 'termcolor'. It is a distutils installed project and thus we cannot accurately determine which files belong to it which would lead to only a partial uninstall.
        "termcolor==1.1.0" \
        #################
    && \
    jupyter lab build && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    echo "${TENSORFLOW}=${TENSORFLOW_VERSION}" >> "${CONDA_DIR}/conda-meta/pinned" && \
    echo "${PYTORCH}=${PYTORCH_VERSION}" >> "${CONDA_DIR}/conda-meta/pinned" && \
    jupyter notebook --generate-config && \
    mamba clean --all -f -y && \
    npm cache clean --force && \
    jupyter lab clean && \
    # Install facets which does not have a pip or conda package at the moment
    git clone https://github.com/PAIR-code/facets.git && \
    jupyter nbextension install facets/facets-dist/ --sys-prefix && \
    rm -rf /tmp/facets && \
    # Import matplotlib the first time to build the font cache.
    MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    # Continue with Base...
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

EXPOSE 8888

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh post_jupyter_start.sh /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY jupyter_server_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root

RUN sed -re "s/c.ServerApp/c.NotebookApp/g" \
    /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    fix-permissions /usr/local/bin/ && \
    fix-permissions /etc/jupyter/  && \
    chmod +x /usr/local/bin/start.sh /usr/local/bin/post_jupyter_start.sh

# HEALTHCHECK documentation: https://docs.docker.com/engine/reference/builder/#healthcheck
# This healtcheck works well for `lab`, `notebook`, `nbclassic`, `server` and `retro` jupyter commands
# https://github.com/jupyter/docker-stacks/issues/915#issuecomment-1068528799
HEALTHCHECK  --interval=15s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -O- --no-verbose --tries=1 --no-check-certificate \
    http${GEN_CERT:+s}://localhost:8888${JUPYTERHUB_SERVICE_PREFIX:-/}api || exit 1

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

WORKDIR "${HOME}"
