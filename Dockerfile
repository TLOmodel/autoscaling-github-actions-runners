FROM summerwind/actions-runner:ubuntu-22.04

# Install system dependencies
RUN /bin/sh -c 'export DEBIAN_FRONTEND=noninteractive \
    && sudo add-apt-repository ppa:deadsnakes/ppa \
    && sudo apt-get update \
    && sudo apt-get install -y python3.11 python3.11-distutils python3.11-venv python3-pip \
    && sudo apt-get --purge autoremove -y \
    && sudo apt-get autoclean \
    && sudo rm -rf /var/lib/apt/lists/*'

# Install tox
RUN sudo python3.11 -m pip install tox

# Install Actions Runners Controller hooks
COPY move_repository.sh /etc/arc/hooks/job-started.d/move_repository.sh

# Create destination directory for the repo
RUN sudo mkdir -p /git && sudo chmod 777 /git
# Clone repository
RUN git clone --depth=1 https://github.com/UCL/TLOmodel /git/repository
# Fetch a file with the latest commit of the repo, to invalidate the local
# Docker cache when the repo is updated.
ADD https://api.github.com/repos/UCL/TLOmodel/git/refs/heads/master version.json
# Update repository, if version changed
RUN git -C /git/repository pull --depth=1
