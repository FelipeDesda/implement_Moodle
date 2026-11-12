#!/bin/bash
# =============================================================================
# Entrypoint para o contêiner Moodle
# Gera automaticamente o config.php com base nas variáveis de ambiente
# =============================================================================

set -e

# Aguarda o banco de dados estar pronto
echo "Aguardando PostgreSQL estar disponível..."
until pg_isready -h "${MOODLE_DATABASE_HOST}" -p "${MOODLE_DATABASE_PORT_NUMBER}" -U "${MOODLE_DATABASE_USER}"; do
  echo "PostgreSQL não está pronto - aguardando..."
  sleep 2
done

echo "PostgreSQL está pronto!"

# Gera o config.php apenas se ele não existir
if [ ! -f /var/www/html/config.php ]; then
    echo "Gerando config.php..."
    cat > /var/www/html/config.php <<EOF
<?php  // Moodle configuration file

unset(\$CFG);
global \$CFG;
\$CFG = new stdClass();

//=========================================================================
// 1. DATABASE SETUP
//=========================================================================
\$CFG->dbtype    = 'pgsql';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = '${MOODLE_DATABASE_HOST}';
\$CFG->dbname    = '${MOODLE_DATABASE_NAME}';
\$CFG->dbuser    = '${MOODLE_DATABASE_USER}';
\$CFG->dbpass    = '${MOODLE_DATABASE_PASSWORD}';
\$CFG->prefix    = 'mdl_';
\$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => '${MOODLE_DATABASE_PORT_NUMBER}',
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_unicode_ci',
);

//=========================================================================
// 2. WEB SITE LOCATION
//=========================================================================
\$CFG->wwwroot   = 'http://localhost:8080';

//=========================================================================
// 3. DATA FILES LOCATION
//=========================================================================
\$CFG->dataroot  = '/var/moodledata';

//=========================================================================
// 4. DATA FILES PERMISSIONS
//=========================================================================
\$CFG->admin     = 'admin';

\$CFG->directorypermissions = 0770;

//=========================================================================
// 5. MOODLE DEBUGGING AND LOGGING
//=========================================================================
// Para ambientes de desenvolvimento, descomente as linhas abaixo:
// @error_reporting(E_ALL | E_STRICT);
// @ini_set('display_errors', '1');
// \$CFG->debug = (E_ALL | E_STRICT);
// \$CFG->debugdisplay = 1;

//=========================================================================
// ALL DONE!  To continue installation, visit your main page with a browser
//=========================================================================

require_once(__DIR__ . '/lib/setup.php');

// There is no php closing tag in this file,
// it is intentional because it prevents trailing whitespace problems!
EOF

    chown www-data:www-data /var/www/html/config.php
    chmod 640 /var/www/html/config.php
    echo "config.php criado com sucesso!"
else
    echo "config.php já existe, pulando geração..."
fi

# Executa o comando original do contêiner (Apache)
exec apache2-foreground
