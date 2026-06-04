# -------------------------------------------------
# Base Image
# VM1과 동일한 Rocky Linux 8 계열 사용
# -------------------------------------------------
FROM rockylinux:8

# -------------------------------------------------
# 기본 패키지 설치
# -------------------------------------------------
RUN dnf update -y && \
    dnf install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    tar \
    python3 \
    python3-pip \
    openssh-clients && \
    dnf clean all

# -------------------------------------------------
# Terraform 설치
# -------------------------------------------------
RUN dnf install -y dnf-plugins-core && \
    dnf config-manager \
    --add-repo \
    https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    dnf install -y terraform

# -------------------------------------------------
# EPEL 저장소
# -------------------------------------------------
RUN dnf install -y epel-release

# -------------------------------------------------
# Ansible 설치
# -------------------------------------------------
RUN dnf install -y ansible

# -------------------------------------------------
# AWS CLI v2 설치
# -------------------------------------------------
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# -------------------------------------------------
# 작업 디렉토리
# -------------------------------------------------
WORKDIR /workspace

CMD ["/bin/bash"]