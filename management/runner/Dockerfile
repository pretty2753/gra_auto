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

# -------------------------------------------------
# GitHub Actions Runner 설치 및 계정 설정
# -------------------------------------------------
# 1) 러너 실행용 non-root 계정 생성 (패스워드 없음)
RUN useradd -m runner && \
    usermod -aG wheel runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 2) 러너 다운로드 및 압축 해제
RUN mkdir -p /home/runner/actions-runner && cd /home/runner/actions-runner && \
    curl -o actions-runner-linux-x64-2.321.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz && \
    tar xzf ./actions-runner-linux-x64-2.321.0.tar.gz && \
    chown -R runner:runner /home/runner/actions-runner

# 3) 의존성 설치 스크립트 실행
RUN /home/runner/actions-runner/bin/installdependencies.sh

# 4) 워크스페이스 권한 부여
RUN chown -R runner:runner /workspace

# 별도 CMD 없이 /bin/bash 로 유지. (사용자가 컨테이너 안에서 ./config.sh 수동 실행 후 ./run.sh 가동)
CMD ["/bin/bash"]