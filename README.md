# AWS Gaming VPN (WireGuard + Global Accelerator)

이 Terraform 구성은 다음 순서로 게이밍 VPN 인프라를 자동화합니다.

1. **커뮤니티 Terraform Provider(`OJFord/wireguard`)로 WireGuard 키 생성**
2. **EC2(t3.micro) + WireGuard 서버 구성** (Amazon Linux 2023, 리전 내 첫 번째 가용 AZ 자동 선택)
3. **AWS Global Accelerator 생성 및 EC2 연결**
4. **로컬 클라이언트 설정 파일 `generated/gaming-vpn.conf` 생성**

## 사전 준비

- Terraform >= 1.5
- AWS 자격증명 설정 (`aws configure` 등)
- 기본 리전: `us-west-1` (필요 시 `aws_region` 변수로 변경)

> 이 구성은 로컬 `wg` CLI 없이 동작합니다. WireGuard 키 생성은 Terraform 커뮤니티 플러그인(`OJFord/wireguard`)이 수행합니다.

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

- 리전 변경: `-var='aws_region=us-west-2'`
- 포트 변경: `-var='wireguard_port=51820'`
- 키 재생성 강제: `-var='key_rotation_token=v2'`

예시:

```bash
terraform apply \
  -var='aws_region=us-west-2' \
  -var='key_rotation_token=v2'
```

## 주의사항

- 서브넷 AZ는 지정값 없이 해당 리전의 첫 번째 가용 AZ를 사용합니다.
- SSH 기본 허용 CIDR은 `0.0.0.0/0`이므로 운영 시 `ssh_ingress_cidrs`를 반드시 제한하세요.
- WireGuard private key가 Terraform state에 저장되므로 state 보안(원격 백엔드 + 암호화 + 접근제어)을 적용하세요.
