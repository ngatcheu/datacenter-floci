DIR      := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ANSIBLE  := ansible-playbook
HOST     := root@192.168.1.120

# Sous WSL, /mnt/c est « world writable » : Ansible y ignore le ansible.cfg du
# répertoire courant. Un chemin explicite est, lui, toujours pris en compte.
export ANSIBLE_CONFIG := $(DIR)ansible.cfg

.DEFAULT_GOAL := help

.PHONY: help deps deploy check ping status logs restart

help: ## Affiche l'aide
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

deps: ## Installe la collection community.docker
	ansible-galaxy collection install -r $(DIR)requirements.yml

deploy: ## Installe Docker et déploie Floci
	$(ANSIBLE) $(DIR)floci-playbook.yml

check: ## Dry-run du playbook
	$(ANSIBLE) $(DIR)floci-playbook.yml --check --diff

ping: ## Vérifie la connectivité SSH
	ansible all -m ping

status: ## État du conteneur et santé des services
	ssh $(HOST) 'docker ps --filter name=floci && curl -s localhost:4566/_localstack/health'

logs: ## Suit les logs Floci
	ssh $(HOST) 'docker logs -f --tail 100 floci'

restart: ## Redémarre Floci
	ssh $(HOST) 'cd /opt/floci && docker compose restart'
