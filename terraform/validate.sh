#!/bin/bash
# ==============================================================================
# Terraform Validation Script
# ==============================================================================
# Este script executa validações de sintaxe, formatação e segurança
# ==============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de output
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

# Header
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║        Terraform Validation - Moodle Infrastructure        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ==============================================================================
# 1. Check Terraform Installation
# ==============================================================================

log_info "Verificando instalação do Terraform..."

if ! command -v terraform &> /dev/null; then
    log_error "Terraform não está instalado!"
    echo "Instale: https://developer.hashicorp.com/terraform/downloads"
    exit 1
fi

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
log_success "Terraform instalado: v$TERRAFORM_VERSION"

# ==============================================================================
# 2. Check AWS CLI
# ==============================================================================

log_info "Verificando AWS CLI..."

if ! command -v aws &> /dev/null; then
    log_warning "AWS CLI não está instalado (opcional para validação)"
else
    AWS_VERSION=$(aws --version | cut -d' ' -f1 | cut -d'/' -f2)
    log_success "AWS CLI instalado: v$AWS_VERSION"
    
    # Check credentials
    if aws sts get-caller-identity &> /dev/null; then
        AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        log_success "Credenciais AWS configuradas (Account: $AWS_ACCOUNT)"
    else
        log_warning "Credenciais AWS não configuradas"
    fi
fi

# ==============================================================================
# 3. Check Directory Structure
# ==============================================================================

log_info "Verificando estrutura de diretórios..."

REQUIRED_DIRS=(
    "modules/networking"
    "modules/compute"
    "modules/database"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        log_error "Diretório não encontrado: $dir"
        exit 1
    fi
done

log_success "Estrutura de diretórios OK"

# ==============================================================================
# 4. Check Required Files
# ==============================================================================

log_info "Verificando arquivos obrigatórios..."

REQUIRED_FILES=(
    "main.tf"
    "variables.tf"
    "outputs.tf"
    "modules/networking/main.tf"
    "modules/compute/main.tf"
    "modules/compute/user_data.sh"
    "modules/database/main.tf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        log_error "Arquivo não encontrado: $file"
        exit 1
    fi
done

log_success "Arquivos obrigatórios OK"

# ==============================================================================
# 5. Terraform Format Check
# ==============================================================================

log_info "Verificando formatação do código..."

if terraform fmt -check -recursive > /dev/null 2>&1; then
    log_success "Código formatado corretamente"
else
    log_warning "Código precisa de formatação. Execute: terraform fmt -recursive"
    terraform fmt -recursive
    log_success "Código reformatado automaticamente"
fi

# ==============================================================================
# 6. Terraform Init
# ==============================================================================

log_info "Inicializando Terraform..."

if terraform init -backend=false > /dev/null 2>&1; then
    log_success "Terraform inicializado"
else
    log_error "Falha ao inicializar Terraform"
    terraform init -backend=false
    exit 1
fi

# ==============================================================================
# 7. Terraform Validate
# ==============================================================================

log_info "Validando configuração Terraform..."

if terraform validate > /dev/null 2>&1; then
    log_success "Configuração válida"
else
    log_error "Configuração inválida"
    terraform validate
    exit 1
fi

# ==============================================================================
# 8. Check for Sensitive Data
# ==============================================================================

log_info "Verificando vazamento de dados sensíveis..."

SENSITIVE_PATTERNS=(
    "password\s*=\s*['\"][^'\"]+['\"]"
    "secret\s*=\s*['\"][^'\"]+['\"]"
    "AKIA[0-9A-Z]{16}"  # AWS Access Key
    "aws_secret_access_key"
)

FOUND_SENSITIVE=0

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -rE "$pattern" --include="*.tf" . > /dev/null 2>&1; then
        log_error "Possível dado sensível encontrado: $pattern"
        FOUND_SENSITIVE=1
    fi
done

if [ $FOUND_SENSITIVE -eq 0 ]; then
    log_success "Nenhum dado sensível encontrado no código"
fi

# ==============================================================================
# 9. Check terraform.tfvars
# ==============================================================================

log_info "Verificando terraform.tfvars..."

if [ ! -f "terraform.tfvars" ]; then
    log_warning "terraform.tfvars não existe. Copie de terraform.tfvars.example"
    log_info "Execute: cp terraform.tfvars.example terraform.tfvars"
else
    log_success "terraform.tfvars existe"
    
    # Check if password is set
    if grep -q "db_password.*=.*\"ChangeMeToSecurePassword123!\"" terraform.tfvars; then
        log_warning "Senha padrão detectada! Altere db_password em terraform.tfvars"
    fi
    
    # Check SSH CIDR
    if grep -q "ssh_allowed_cidr.*=.*\"0.0.0.0/0\"" terraform.tfvars; then
        log_warning "SSH aberto para internet! Restrinja ssh_allowed_cidr ao seu IP"
    fi
fi

# ==============================================================================
# 10. Check .gitignore
# ==============================================================================

log_info "Verificando .gitignore..."

if [ -f ".gitignore" ]; then
    if grep -q "*.tfvars" .gitignore; then
        log_success ".gitignore configurado corretamente"
    else
        log_warning ".gitignore não contém *.tfvars"
    fi
else
    log_warning ".gitignore não encontrado"
fi

# ==============================================================================
# 11. Optional: tflint (if installed)
# ==============================================================================

if command -v tflint &> /dev/null; then
    log_info "Executando tflint..."
    if tflint --init > /dev/null 2>&1 && tflint > /dev/null 2>&1; then
        log_success "tflint passou sem erros"
    else
        log_warning "tflint encontrou problemas"
        tflint
    fi
else
    log_info "tflint não instalado (opcional)"
fi

# ==============================================================================
# 12. Optional: terraform-docs (if installed)
# ==============================================================================

if command -v terraform-docs &> /dev/null; then
    log_info "Gerando documentação..."
    terraform-docs markdown table . > TERRAFORM_DOCS.md
    log_success "Documentação gerada: TERRAFORM_DOCS.md"
else
    log_info "terraform-docs não instalado (opcional)"
fi

# ==============================================================================
# Summary
# ==============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    VALIDATION COMPLETE                     ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ $FOUND_SENSITIVE -eq 0 ]; then
    log_success "Todas as validações passaram!"
    echo ""
    log_info "Próximos passos:"
    echo "  1. Configure terraform.tfvars com seus valores"
    echo "  2. Execute: terraform plan -out=tfplan"
    echo "  3. Execute: terraform apply tfplan"
    echo ""
    exit 0
else
    log_error "Algumas validações falharam. Corrija os erros acima."
    exit 1
fi
