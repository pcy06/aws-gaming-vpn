# AWS Gaming VPN (WireGuard + Global Accelerator)

이 Terraform 구성은 다음 순서로 게이밍 VPN 인프라를 자동화합니다.

1. **로컬 WireGuard 키 생성** (`wg genkey`)
2. **EC2(t3.micro) + WireGuard 서버 구성** (기본값: `us-west-2-lax-1a` 선호)
3. **AWS Global Accelerator 생성 및 EC2 연결**
4. **로컬 클라이언트 설정 파일 `generated/gaming-vpn.conf` 생성**

## 사전 준비

- Terraform >= 1.5
- AWS 자격증명 설정 (`aws configure` 등)
- 로컬에 `wg` 명령어 설치 (WireGuard tools)
  - Ubuntu 예: `sudo apt-get install wireguard-tools`
  - macOS(Homebrew) 예: `brew install wireguard-tools`

## 사용 방법

```bash
terraform init
terraform apply
```

완료 후 아래 출력값을 확인하세요.

- `global_accelerator_dns_name`
- `global_accelerator_static_ips`
- `client_config_path` (기본: `generated/gaming-vpn.conf`)

## 커스터마이징

- Local Zone 선호값: `-var='local_zone_name=us-west-2-lax-1a'`
- 포트 변경: `-var='wireguard_port=51820'`
- 키 재생성 강제: `-var='key_rotation_token=v2'`

예시:

```bash
terraform apply \
  -var='local_zone_name=us-west-2-lax-1a' \
  -var='key_rotation_token=v2'
```

## 주의사항

- `us-west-2-lax-1a`는 계정에서 Local Zone opt-in이 되어 있어야 사용 가능합니다.
- 사용 불가한 경우 Terraform이 가용한 첫 번째 AZ로 자동 폴백합니다.
- SSH 기본 허용 CIDR은 `0.0.0.0/0`이므로 운영 시 `ssh_ingress_cidrs`를 반드시 제한하세요.
