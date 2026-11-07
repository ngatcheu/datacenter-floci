# datacenter-floci

Déploiement de [Floci](https://github.com/hectorvent/floci) — émulateur AWS local
(S3, SQS, SNS, DynamoDB, Lambda, IAM, RDS, EKS…) — via Ansible + Docker Compose.

| | |
|---|---|
| Hôte | `standalone-1` — `192.168.1.120` (VM `terragrunt_cluster_kubernetes/live/production/standalone`) |
| Version | `floci/floci:2.4.0` (épinglée dans `floci-playbook.yml`) |
| API AWS | `http://floci.homelab.local:4566` (ou `http://192.168.1.120:4566`) |
| Console | `http://192.168.1.120:4500` |
| Données | `/opt/floci/data` (mode `hybrid` : écriture disque toutes les 5 s) |

## Architecture

```
standalone-1 (Rocky 9, Docker)
├── floci          (conteneur, port 4566, socket Docker monté)
├── floci-aws-ui   (sidecar console lancé par Floci, port 4500)
└── conteneurs frères créés à la demande par Floci (réseau Docker « floci ») :
    Lambda, RDS (postgres/mysql), ElastiCache (valkey), EKS (k3s)…
```

Le socket Docker est monté dans Floci : il peut lancer n'importe quel conteneur
sur l'hôte. Ne l'exposer que sur le LAN du homelab.

## Prérequis

- VM `standalone-1` créée (`make infra-apply CLUSTER=standalone` dans `terragrunt_cluster_kubernetes`)
- `ansible` ≥ 2.16, accès SSH root à la VM
- DNS : `floci.homelab.local` → `192.168.1.120` dans `pihole-dns/group_vars/dns_servers.yml` (`make dns` dans `pihole-dns/`)

## Utilisation

```bash
make deps      # collection community.docker
make deploy    # installe Docker + déploie Floci (idempotent)
make status    # conteneurs + santé des services
make logs
make restart
```

Changer de version : modifier `floci_version` dans `floci-playbook.yml`, puis `make deploy`.

## Clients

Identifiants factices acceptés (l'authentification n'est pas vérifiée) :

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://floci.homelab.local:4566

aws s3 mb s3://demo
aws sqs create-queue --queue-name demo
```

Terraform :

```hcl
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = "http://floci.homelab.local:4566"
    sqs      = "http://floci.homelab.local:4566"
    dynamodb = "http://floci.homelab.local:4566"
  }
}
```
