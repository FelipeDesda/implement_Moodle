# Correções Aplicadas no Setup do Moodle

## Problema 1: Extensão PostgreSQL faltando
**Erro:** "O PHP não foi configurado corretamente com a extensão PGSQL"

**Solução:** Adicionada a extensão `pgsql` ao Dockerfile (linha após `intl`):
```dockerfile
pgsql \
pdo_pgsql \
```

## Problema 2: Conexão com banco de dados falhando
**Erro:** "connection to server at 'localhost' (::1), port 5432 failed: Connection refused"

**Causa:** O Moodle estava tentando se conectar a `localhost` em vez do serviço `db` do Docker.

**Solução:** Criado script de entrypoint (`docker-entrypoint.sh`) que:
1. Aguarda o PostgreSQL estar pronto usando `pg_isready`
2. Gera automaticamente o arquivo `config.php` com as configurações corretas do banco de dados
3. Utiliza as variáveis de ambiente do `docker-compose.yml` para configurar a conexão

## Arquivos Modificados

### 1. `Dockerfile`
- Adicionado `postgresql-client` nas dependências do sistema
- Adicionada extensão PHP `pgsql`
- Adicionado `COPY` do script de entrypoint
- Adicionado `ENTRYPOINT` customizado

### 2. `docker-entrypoint.sh` (novo arquivo)
- Script bash que:
  - Verifica se o PostgreSQL está pronto
  - Gera `config.php` automaticamente com as variáveis de ambiente
  - Inicia o Apache

## Como usar

1. Certifique-se de que o arquivo `.env.example` contém as configurações corretas
2. Execute:
   ```bash
   docker compose down
   docker compose build --no-cache
   docker compose up -d
   ```
3. Acesse http://localhost:8080
4. Complete a instalação do Moodle através da interface web

## Verificação

Para verificar se as extensões estão instaladas:
```bash
docker exec docker-moodle-1 php -m | Select-String -Pattern "pgsql"
```

Para verificar a configuração do banco:
```bash
docker exec docker-moodle-1 cat /var/www/html/config.php
```

## Status
✅ Extensão PostgreSQL instalada  
✅ Conexão com banco de dados configurada  
✅ Config.php gerado automaticamente  
✅ Containers rodando corretamente  
