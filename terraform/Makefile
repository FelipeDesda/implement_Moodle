# ==============================================================================
# Makefile - Terraform Moodle Infrastructure
# ==============================================================================

.PHONY: help init validate plan apply destroy clean fmt check ssh logs output

# Variáveis
TFVARS_FILE := terraform.tfvars
PLAN_FILE := tfplan

# Default target
.DEFAULT_GOAL := help

## help: Mostra esta mensagem de ajuda
help:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║        Terraform Moodle Infrastructure - Makefile          ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Targets disponíveis:"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
	@echo ""

## init: Inicializa o Terraform (downloads providers)
init:
	@echo "🔧 Inicializando Terraform..."
	terraform init

## validate: Valida a sintaxe dos arquivos Terraform
validate:
	@echo "✅ Validando configuração..."
	terraform validate

## fmt: Formata todos os arquivos .tf
fmt:
	@echo "🎨 Formatando arquivos Terraform..."
	terraform fmt -recursive

## check: Executa fmt + validate
check: fmt validate
	@echo "✅ Verificação completa!"

## setup: Cria terraform.tfvars a partir do exemplo
setup:
	@if [ ! -f $(TFVARS_FILE) ]; then \
		cp terraform.tfvars.example $(TFVARS_FILE); \
		echo "📝 Arquivo $(TFVARS_FILE) criado!"; \
		echo "⚠️  EDITE O ARQUIVO E CONFIGURE:"; \
		echo "   - db_password"; \
		echo "   - ssh_allowed_cidr"; \
		echo "   - ec2_key_name"; \
	else \
		echo "⚠️  Arquivo $(TFVARS_FILE) já existe!"; \
	fi

## plan: Cria plano de execução
plan: check
	@echo "📋 Criando plano de execução..."
	terraform plan -out=$(PLAN_FILE)
	@echo "✅ Plano salvo em: $(PLAN_FILE)"

## apply: Aplica a infraestrutura (requer plan)
apply:
	@if [ ! -f $(PLAN_FILE) ]; then \
		echo "❌ Erro: Execute 'make plan' primeiro!"; \
		exit 1; \
	fi
	@echo "🚀 Aplicando infraestrutura..."
	terraform apply $(PLAN_FILE)
	@rm -f $(PLAN_FILE)
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║             INFRAESTRUTURA CRIADA COM SUCESSO!             ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@make output

## output: Mostra outputs da infraestrutura
output:
	@terraform output connection_instructions

## destroy: Destrói toda a infraestrutura
destroy:
	@echo "⚠️  ATENÇÃO: Esta ação irá DESTRUIR toda a infraestrutura!"
	@echo "Pressione Ctrl+C para cancelar..."
	@sleep 5
	terraform destroy

## clean: Remove arquivos temporários
clean:
	@echo "🧹 Limpando arquivos temporários..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f $(PLAN_FILE)
	rm -f crash.log
	rm -f *.tfstate*
	@echo "✅ Limpeza concluída!"

## ssh: Conecta via SSH na instância EC2
ssh:
	@echo "🔐 Conectando via SSH..."
	@EC2_IP=$$(terraform output -raw ec2_public_ip 2>/dev/null); \
	if [ -z "$$EC2_IP" ]; then \
		echo "❌ Erro: Infraestrutura não está provisionada!"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/vockey.pem ec2-user@$$EC2_IP

## logs: Mostra logs do Moodle (requer SSH)
logs:
	@echo "📜 Obtendo logs do Moodle..."
	@EC2_IP=$$(terraform output -raw ec2_public_ip 2>/dev/null); \
	if [ -z "$$EC2_IP" ]; then \
		echo "❌ Erro: Infraestrutura não está provisionada!"; \
		exit 1; \
	fi; \
	ssh -i ~/.ssh/vockey.pem ec2-user@$$EC2_IP 'sudo docker logs moodle --tail 100'

## status: Verifica status dos recursos
status:
	@echo "📊 Status da infraestrutura:"
	@terraform show -json 2>/dev/null | jq -r '.values.root_module.resources[] | "\(.type): \(.name)"' || echo "Nenhum recurso provisionado"

## refresh: Atualiza state com estado real da AWS
refresh:
	@echo "🔄 Atualizando state..."
	terraform refresh

## graph: Gera gráfico de dependências (requer graphviz)
graph:
	@echo "📊 Gerando gráfico de dependências..."
	terraform graph | dot -Tpng > infrastructure-graph.png
	@echo "✅ Gráfico salvo: infrastructure-graph.png"

## cost: Estima custos (requer infracost)
cost:
	@if command -v infracost >/dev/null 2>&1; then \
		echo "💰 Estimando custos..."; \
		infracost breakdown --path .; \
	else \
		echo "⚠️  infracost não instalado. Instale: https://www.infracost.io/docs/"; \
	fi

## health: Executa health check do Moodle
health:
	@echo "🏥 Executando health check..."
	@EC2_DNS=$$(terraform output -raw ec2_public_dns 2>/dev/null); \
	if [ -z "$$EC2_DNS" ]; then \
		echo "❌ Erro: Infraestrutura não está provisionada!"; \
		exit 1; \
	fi; \
	cd .. && ./scripts/health-check.sh $$EC2_DNS
