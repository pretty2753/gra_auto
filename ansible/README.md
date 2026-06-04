# Ansible Playbook 실행 방법

> 모든 명령은 `ansible/` 디렉토리 기준으로 실행합니다.

```bash
cd ansible
```

---

## 1. 초기 서버 Bootstrap

초기 서버 설정용 플레이북입니다.

주요 작업:
- `adreamin` 계정 생성
- SSH 키 등록
- sudo 권한 설정
- 기본 패키지 및 의존성 설치
- Ansible 관리 대상 서버 초기 구성

Terraform으로 인프라 생성 후 최초 1회만 실행합니다.

```bash
ansible-playbook -i inventories/bootstrap/inventory.yml playbooks/bootstrap.yml
```

---

## 3. ami capture (AutoScaling 적용시)

was 서버를 이미지화 시킵니다.
```bash
cd ansible
source .venv/bin/activate
(vevn) ansible-playbook -i inventories/dev/inventory.yml playbooks/ami_capture.yml
```

[ERROR]: Task failed: Module failed: Failed to import the required Python library (botocore and boto3)
```bash
cd ansible
python3 -m venv .venv
source .venv/bin/activate
pip install boto3 botocore
```

---

## 기타. FastAPI 애플리케이션 재배포

`event_service` 소스 수정 후 FastAPI 애플리케이션만 재배포합니다.

주요 작업:
- FastAPI 소스 동기화
- Python 패키지 업데이트
- 애플리케이션 재실행

```bash
ansible-playbook -i inventories/dev/inventory.yml playbooks/deploy_fastapi.yml
```

---

## 기타. FastAPI 애플리케이션 재배포

`event_service` 소스 수정 후 FastAPI 애플리케이션만 재배포합니다.

주요 작업:
- FastAPI 소스 동기화
- Python 패키지 업데이트
- 애플리케이션 재실행

```bash
ansible-playbook -i inventories/dev/inventory.yml playbooks/deploy_fastapi.yml
```