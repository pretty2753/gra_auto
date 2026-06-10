# GitHub Actions Self-Hosted Runner 실행 가이드

`mgmt-runner` 컨테이너 내부에서 GitHub Actions Self-Hosted Runner를 구성하고 실행하는 가이드입니다.

---

## 1. 러너 컨테이너 접속

현재 실행 중인 `mgmt-runner` 컨테이너에 `runner` 계정(비루트 계정)으로 바로 접속합니다.

```bash
docker exec -it -u runner mgmt-runner /bin/bash
```

> [!NOTE]  
> 만약 실수로 `root` 계정으로 접속했다면, 아래 명령어로 `runner` 계정으로 전환할 수 있습니다.
> ```bash
> su - runner
> ```

---

## 2. 러너 설치 디렉토리 이동

러너 실행 파일과 스크립트가 설치된 디렉토리로 이동합니다.

```bash
cd /home/runner/actions-runner
```

---

## 3. 셀프 호스티드 러너 등록 (최초 1회)

러너가 아직 GitHub 저장소에 등록되지 않은 경우, 아래 등록 스크립트를 실행합니다.  
*(이미 등록되어 있다면 이 단계를 건너뛰고 바로 **4번**으로 진행하세요.)*

1. GitHub 저장소의 **Settings > Actions > Runners > New self-hosted runner** 페이지로 이동하여 토큰을 확인합니다.
2. 아래 명령어를 실행하여 등록을 진행합니다.

```bash
./config.sh --url https://github.com/leesk0007/InfraBoys --token <YOUR_GITHUB_RUNNER_TOKEN>
```

> [!TIP]  
> 등록 과정 중 입력 대기(Runner group, Runner name, tags 등)가 나타나면 별도의 커스텀 설정이 필요 없는 한 **Enter(기본값)**를 입력하여 편리하게 완료할 수 있습니다.

---

## 4. 러너 실행

### 대화형 실행 (포그라운드)
콘솔 로그를 확인하며 테스트할 때 사용합니다.
```bash
./run.sh
```

### 백그라운드 실행
세션이 종료되어도 러너가 계속 동작하도록 백그라운드 프로세스로 실행합니다.
```bash
nohup ./run.sh > runner.log 2>&1 &
```

* **로그 확인 방법**:
  ```bash
  tail -f runner.log
  ```

* **러너 정지 방법**:
  ```bash
  # run.sh 프로세스 ID(PID) 확인 후 종료
  ps aux | grep run.sh
  kill -15 <PID>
  ```
