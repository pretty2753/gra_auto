# InfraBoys - 하이브리드 인프라 프로젝트

## 1. 프로젝트 개요

온프레미스(VM) + AWS 클라우드를 결합한 **하이브리드 인프라** 구축 프로젝트.
서비스 자체보다 **인프라 자동화(IaC)와 운영 환경 구성**에 초점을 맞춘다.

---

## 2. 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────────┐
│                        온프레미스 환경                                │
│                                                                     │
│  ┌─── VM1 (현재 서버) ──────────────────────────────────────────┐   │
│  │                                                               │   │
│  │  ┌─────────────┐  ┌──────────┐  ┌────────────────────────┐  │   │
│  │  │ mgmt-runner │  │ FastAPI  │  │  모니터링 스택          │  │   │
│  │  │ (컨테이너)   │  │ (컨테이너) │  │  Prometheus (컨테이너) │  │   │
│  │  │             │  │          │  │  Grafana    (컨테이너)  │  │   │
│  │  │ • Terraform │  │  이벤트   │  │  Alertmanager(컨테이너)│  │   │
│  │  │ • Ansible   │  │  당첨조회  │  └────────────────────────┘  │   │
│  │  │ • AWS CLI   │  │  서비스   │                               │   │
│  │  └──────┬──────┘  └──────────┘                               │   │
│  │         │                                                     │   │
│  │         │ IaC 프로비저닝                                       │   │
│  └─────────┼─────────────────────────────────────────────────────┘   │
│            │                                                         │
│  ┌─── VM2 (추후 구성) ──┐                                           │
│  │  (미정)              │                                           │
│  └──────────────────────┘                                           │
└────────────┼────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    AWS 클라우드 (ap-northeast-2)                      │
│                                                                     │
│  ┌─── VPC (10.0.0.0/16) ───────────────────────────────────────┐   │
│  │                                                               │   │
│  │  ┌── 퍼블릭 서브넷 ──────────────────────────────────────┐   │   │
│  │  │  Bastion (10.0.1.0/24)  ← SSH 진입점 + NAT 인스턴스    │   │   │
│  │  │  ALB-A   (10.0.2.0/24)  ← 로드밸런서 (AZ-a)           │   │   │
│  │  │  ALB-B   (10.0.3.0/24)  ← 로드밸런서 (AZ-b)           │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  │                          │                                     │   │
│  │                     ALB (트래픽 분배)                           │   │
│  │                          │                                     │   │
│  │  ┌── 프라이빗 서브넷 1 (WAS) ─────────────────────────────┐   │   │
│  │  │  (10.0.10.0/24)                                         │   │   │
│  │  │  EC2 WAS 인스턴스들 ← ASG로 자동 확장/축소               │   │   │
│  │  │  (FastAPI + Nginx + Node Exporter)                      │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  │                          │                                     │   │
│  │  ┌── 프라이빗 서브넷 2 (DB) ──────────────────────────────┐   │   │
│  │  │  (10.0.30.0/24)                                         │   │   │
│  │  │  PostgreSQL DB 서버 (단일)                                │   │   │
│  │  │  (PostgreSQL + Node Exporter + Postgres Exporter)       │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  │                                                               │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  S3 (tfstate 저장) + DynamoDB (state lock)                          │
│  Route 53 (infrastudy.store)                                        │
│  IAM (Bastion EC2 → Prometheus Discovery 용)                        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. 현재 상태 분석

### ✅ 완료된 작업

| 항목 | 상태 | 설명 |
|------|------|------|
| VM1 기본 OS 셋팅 | ✅ | Rocky Linux 8 기반 |
| Docker / Docker Compose | ✅ | 컨테이너 4개 정상 가동 중 |
| mgmt-runner 컨테이너 | ✅ | Terraform + Ansible + AWS CLI 설치 완료 |
| Prometheus 컨테이너 | ✅ | 설정 파일 연동 완료 (아직 EC2 타겟 미등록) |
| Grafana 컨테이너 | ✅ | Prometheus 데이터소스 자동 등록 완료 |
| Alertmanager 컨테이너 | ✅ | 기본 라우팅만 설정 (알림 수신자 미설정) |
| AWS CLI 환경변수 | ✅ | .env 파일 → mgmt-runner 주입 확인 완료 |
| Terraform 모듈 구조 | ✅ | vpc, subnet, ec2, alb, asg 등 10개 모듈 작성 |
| Terraform S3 Backend | ✅ | S3 버킷 + DynamoDB Lock 테이블 코드 작성 |
| Terraform dev 환경 코드 | ✅ | 네트워크 → 보안 → 컴퓨트 → ALB → ASG → Route53 |
| Ansible 역할(Role) 구조 | ✅ | bootstrap, nginx, fastapi, postgresql, 모니터링 등 11개 |
| Ansible Inventory 자동생성 | ✅ | Terraform에서 EC2 IP 기반 inventory.yml 자동 생성 |
| GitHub Actions 워크플로우 | ✅ | deploy, terraform-plan, terraform-apply 작성 |
| FastAPI 이벤트 서비스 | ✅ | dev/deploy 코드 분리, PostgreSQL 연동 |

### ⚠️ 확인/수정 필요 사항

| 항목 | 상태 | 설명 |
|------|------|------|
| NAT 인스턴스 vs NAT Gateway | ⚠️ | 현재 코드는 NAT Gateway 사용 중. NAT 인스턴스로 바꿔야 함 |
| FastAPI 컨테이너 (VM1용) | ⚠️ | docker-compose.yml에 FastAPI 서비스 미정의 |
| `terraform/envs/prod` | ⚠️ | .gitkeep만 존재, 코드 없음 |

---

## 4. 단계별 실행 계획

### Phase 0: 사전 준비 (현재 단계)
> mgmt-runner 컨테이너에서 Terraform/Ansible을 문제없이 실행할 수 있는 환경 확보

- [x] Docker Compose로 mgmt-runner 컨테이너 실행
- [x] AWS 자격증명 환경변수 주입 (.env → docker-compose)
- [ ] **mgmt-runner 컨테이너에서 AWS 연결 테스트**
  ```bash
  docker exec -it mgmt-runner aws sts get-caller-identity
  ```
- [ ] **SSH 키 볼륨 마운트 설정** (Ansible에서 EC2에 접속하기 위해 필요)
  - docker-compose.yml에 `~/.ssh:/root/.ssh:ro` 마운트 추가 검토
- [ ] `.githhub` → `.github` 디렉토리명 수정

---

### Phase 1: Terraform Bootstrap (S3 + DynamoDB 백엔드)
> Terraform State를 안전하게 관리하기 위한 원격 백엔드 생성

- [ ] mgmt-runner 컨테이너 내부에서 실행:
  ```bash
  cd /workspace/terraform/bootstrap
  terraform init
  terraform plan
  terraform apply
  ```
- [ ] S3 버킷(`project01-tfstate-bucket`) 생성 확인
- [ ] DynamoDB 테이블(`dream-team-terraform-lock`) 생성 확인

---

### Phase 2: 네트워크 인프라 구성 (Terraform)
> 클라우드의 뼈대가 되는 VPC, 서브넷, 라우팅 구성

- [ ] **NAT 인스턴스로 변경** (현재 NAT Gateway → NAT Instance)
  - `03_routing.tf`의 NAT Gateway 모듈을 NAT 인스턴스 모듈로 교체
  - NAT 인스턴스용 보안 그룹 추가
  - 소스/대상 확인(Source/Dest Check) 비활성화 설정
- [ ] Terraform Init + Plan 실행 (mgmt-runner 내부):
  ```bash
  cd /workspace/terraform/envs/dev
  terraform init
  terraform plan
  ```
- [ ] 네트워크 리소스만 우선 Apply:
  ```bash
  terraform apply -target=module.project01_vpc \
                  -target=module.igw \
                  -target=module.project01_public_subnet_bastion \
                  -target=module.project01_public_subnet_alb_a \
                  -target=module.project01_public_subnet_alb_b \
                  -target=module.project01_private_subnet_was \
                  -target=module.project01_private_subnet_db
  ```

---

### Phase 3: 보안 + 컴퓨트 인프라 구성 (Terraform)
> 보안 그룹, EC2 인스턴스(Bastion + WAS + DB) 생성

- [ ] 보안 그룹 + 라우팅 테이블 Apply
- [ ] IAM Role/Profile Apply
- [ ] EC2 인스턴스(Bastion, WAS, DB) Apply
- [ ] ALB + Target Group Apply
- [ ] Ansible Inventory 자동 생성 확인 (`08_ansible.tf`에 의해)
- [ ] SSH 접속 테스트:
  ```bash
  # Bastion 접속
  ssh -i ~/.ssh/project01-bastion-key.pem ec2-user@<bastion_public_ip>
  # WAS 접속 (Bastion 경유)
  ssh -i ~/.ssh/project01-was-key.pem -o ProxyJump=ec2-user@<bastion_ip> ec2-user@<was_private_ip>
  ```

---

### Phase 4: 서버 초기 설정 (Ansible Bootstrap)
> EC2 인스턴스에 공통 계정 생성 및 기본 패키지 설치

- [ ] mgmt-runner에서 Ansible Bootstrap 실행:
  ```bash
  cd /workspace/ansible
  ansible-playbook -i inventories/bootstrap/inventory.yml playbooks/bootstrap.yml
  ```
- [ ] `adreamin` 계정 생성 확인 (Bastion, WAS, DB 모두)
- [ ] SSH 키 교환(bastion-key, ansible-key) 완료 확인
- [ ] sudo 권한 설정 확인

---

### Phase 5: 서비스 소프트웨어 설치 (Ansible Site)
> 각 EC2 역할에 맞는 소프트웨어 설치 및 서비스 배포

- [ ] Site Playbook 실행:
  ```bash
  cd /workspace/ansible
  ansible-playbook -i inventories/dev/inventory.yml playbooks/site.yml
  ```
- [ ] **Bastion 서버**: Swap, Grafana(?), Prometheus(?) 설치
  - ※ 현재 site.yml에 bastion에 Grafana/Prometheus가 설정되어 있는데,
    VM1에서 이미 컨테이너로 돌리고 있으므로 **중복 여부 검토 필요**
- [ ] **WAS 서버**: Nginx + FastAPI 배포 + Node Exporter
- [ ] **DB 서버**: PostgreSQL + Node Exporter + Postgres Exporter
- [ ] ALB 헬스체크 통과 확인 (WAS 서비스 정상 가동)

---

### Phase 6: Auto Scaling 구성 (Terraform 2차)
> WAS 서버 이미지를 기반으로 ASG를 구성하여 자동 확장 적용

- [ ] WAS 서버에서 AMI 캡처:
  ```bash
  cd /workspace/ansible
  ansible-playbook -i inventories/dev/inventory.yml playbooks/ami_capture.yml
  ```
- [ ] 캡처된 AMI ID 확인
- [ ] ASG 모듈에 AMI ID를 넣고 Apply:
  ```bash
  cd /workspace/terraform/envs/dev
  terraform apply -var="ami_id=ami-xxxxxxxxx" -target=module.asg
  ```
- [ ] ASG 인스턴스들이 ALB Target Group에 자동 등록되는지 확인
- [ ] 기존 단독 WAS EC2 인스턴스 정리 여부 결정

---

### Phase 7: 모니터링 연동 (VM1 ↔ AWS EC2)
> VM1의 Prometheus가 클라우드 EC2 인스턴스의 메트릭을 수집하도록 연동

- [ ] `prometheus/prometheus.yml`에 EC2 Node Exporter 타겟 추가
  ```yaml
  scrape_configs:
    - job_name: was-nodes
      static_configs:
        - targets:
            - <was_private_ip>:9100
    - job_name: db-node
      static_configs:
        - targets:
            - <db_private_ip>:9100
            - <db_private_ip>:9187  # postgres exporter
  ```
  - ※ 또는 Bastion IAM Role 기반 EC2 Service Discovery(`ec2_sd_configs`) 사용 검토
- [ ] Grafana 대시보드 구성
- [ ] Alertmanager 알림 수신자(Slack/Email 등) 설정

---

### Phase 8: CI/CD 파이프라인 구성
> GitHub Actions + Self-Hosted Runner를 통한 배포 자동화

- [ ] `.githhub` → `.github` 디렉토리명 수정
- [ ] Self-Hosted Runner 컨테이너 구성 (VM1에서 실행)
- [ ] GitHub Secrets 설정:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `BASTION_PRIVATE_KEY`
  - `ANSIBLE_PRIVATE_KEY`
- [ ] 워크플로우 동작 검증:
  - PR 생성 시 → `terraform plan` 자동 실행
  - main 머지 시 → `terraform apply` + 배포 자동 실행

---

## 5. 디렉토리 구조

```
project2/
├── .env                          # AWS 자격증명 (git 미추적)
├── .env.example                  # .env 템플릿
├── .gitignore
├── docker-compose.yml            # VM1 컨테이너 오케스트레이션
│
├── management/
│   └── runner/
│       └── Dockerfile            # mgmt-runner 이미지 (Terraform + Ansible + AWS CLI)
│
├── terraform/
│   ├── bootstrap/                # S3 Backend + DynamoDB Lock 생성용
│   │   ├── provider.tf
│   │   ├── version.tf
│   │   ├── s3.tf
│   │   └── dynamodb.tf
│   ├── modules/                  # 재사용 가능한 Terraform 모듈
│   │   ├── vpc/
│   │   ├── subnet/
│   │   ├── internet-gateway/
│   │   ├── nat-gateway/          # → NAT 인스턴스 모듈로 교체 예정
│   │   ├── security-group/
│   │   ├── keypair/
│   │   ├── ec2/
│   │   ├── alb/
│   │   ├── asg/
│   │   └── route53/
│   └── envs/
│       ├── dev/                  # 개발 환경 (현재 주력)
│       └── prod/                 # 운영 환경 (아직 미구성)
│
├── ansible/
│   ├── ansible.cfg
│   ├── inventories/
│   │   ├── bootstrap/            # 초기 설정용 (ec2-user 기반)
│   │   └── dev/                  # 서비스 배포용 (adreamin 기반)
│   ├── playbooks/
│   │   ├── bootstrap.yml         # Phase 4: 초기 계정/키 설정
│   │   ├── site.yml              # Phase 5: 전체 서비스 설치
│   │   ├── deploy_fastapi.yml    # 핫픽스용 FastAPI 재배포
│   │   └── ami_capture.yml       # Phase 6: AMI 캡처
│   └── roles/
│       ├── bootstrap_user/       # 계정 생성 + SSH 키 교환
│       ├── common/               # 기본 패키지
│       ├── swap/                 # Swap 메모리 설정
│       ├── nginx/                # Nginx 리버스 프록시
│       ├── fastapi/              # FastAPI 배포
│       ├── postgresql/           # PostgreSQL 설치/설정
│       ├── node_exporters/       # Prometheus Node Exporter
│       ├── postgres_exporters/   # Prometheus Postgres Exporter
│       ├── monitoring_grafana/   # Grafana 설치
│       ├── monitoring_prometheus/# Prometheus 설치
│       └── ami_capture/          # AMI 이미지 생성
│
├── web/
│   └── event_service/            # FastAPI 이벤트 당첨 조회 서비스
│       ├── dev/                  # 로컬 개발용 (SQLite/직접 DB IP)
│       └── deploy/               # 클라우드 배포용 (환경변수 기반 DB)
│
├── prometheus/
│   └── prometheus.yml            # Prometheus 수집 설정
│
├── grafana/
│   └── provisioning/
│       └── datasources/
│           └── datasource.yml    # Prometheus 자동 등록
│
└── alertmanager/
    └── alertmanager.yml          # 알림 라우팅 설정
```

---

## 6. 핵심 결정 사항 (논의 필요)

### Q1. NAT Gateway vs NAT 인스턴스
현재 `03_routing.tf`에서 **NAT Gateway 모듈**을 사용 중입니다.
NAT 인스턴스로 바꾸려면 새로운 모듈을 만들거나 기존 `nat-gateway` 모듈을 교체해야 합니다.
- NAT 인스턴스: 비용 절감 (t3.micro 프리티어 활용 가능), 직접 관리 필요
- NAT Gateway: AWS 관리형, 고가용성, 비용 높음

### Q2. Bastion 서버의 Prometheus/Grafana 중복
현재 Ansible `site.yml`에서 Bastion 서버에 Prometheus와 Grafana를 설치하도록 되어 있지만,
VM1에서 이미 Docker 컨테이너로 운영 중입니다.
- **안 A**: VM1 컨테이너만 사용 (Bastion의 모니터링 역할 제거)
- **안 B**: Bastion에서 운영하고 VM1 컨테이너 제거
- **안 C**: 둘 다 유지 (이중화 / 용도 분리)

### Q3. Self-Hosted Runner 구성
GitHub Actions의 `terraform-plan.yml`과 `terraform-apply.yml`이 `runs-on: self-hosted`로 되어있습니다.
현재 Self-Hosted Runner 컨테이너가 docker-compose.yml에 정의되어 있지 않습니다.
mgmt-runner를 Self-Hosted Runner로 겸용할지, 별도 컨테이너를 띄울지 결정이 필요합니다.

### Q4. SSH 키 관리 전략
mgmt-runner 컨테이너에서 Ansible을 통해 EC2에 SSH 접속하려면
생성된 SSH 키를 컨테이너 내부에서 접근할 수 있어야 합니다.
- **방법**: 호스트의 `~/.ssh` 디렉토리를 볼륨 마운트
- **docker-compose.yml에 추가**: `- ~/.ssh:/root/.ssh:ro`

---

## 7. 당장 다음으로 해야 할 일 (우선순위)

| 순서 | 작업 | 예상 소요 |
|------|------|-----------|
| 1 | mgmt-runner에서 `aws sts get-caller-identity` 테스트 | 1분 |
| 2 | 위 핵심 결정사항 (Q1~Q4) 논의 및 결정 | 팀 논의 |
| 3 | NAT 인스턴스 모듈 작성 or NAT Gateway 유지 결정 | 30분~1시간 |
| 4 | Terraform Bootstrap 실행 (S3 + DynamoDB) | 5분 |
| 5 | Terraform Plan으로 전체 인프라 검증 | 10분 |
| 6 | Terraform Apply로 클라우드 인프라 생성 | 10~15분 |
| 7 | Ansible Bootstrap으로 서버 초기 설정 | 5분 |
| 8 | Ansible Site로 서비스 배포 | 10분 |
