#!/usr/bin/env bash
# ddev-docktopus-drupal bootstrap. Runs on every `ddev restart` (via the
# post-start hook in config.ddev-docktopus-drupal.yaml) and is idempotent:
#ddev-generated
#
#  - .installed marker present  -> already handled, exit silently
#  - .skip file present         -> opted out, exit silently
#  - composer.json exists       -> existing project: untouched, marked done
#  - empty project              -> create a Drupal 11 site + stack modules
#
# Requirements for the empty-project path (one-time, before `ddev restart`):
#   ddev config --project-type=drupal11 --docroot=web
#   ddev start
#   ddev add-on get juancalero/ddev-docktopus-drupal
#   ddev restart        <- bootstrap runs here (takes a few minutes)
#
# Opt out of the automatic bootstrap at any time:
#   touch .ddev/docktopus-drupal/.skip

set -eu -o pipefail

STATE_DIR=".ddev/docktopus-drupal"
MARKER="$STATE_DIR/.installed"

if [ -f "$MARKER" ] || [ -f "$STATE_DIR/.skip" ]; then
  exit 0
fi

# ---------------------------------------------------------------- existing
if [ -f composer.json ]; then
  echo "ddev-docktopus-drupal: existing project detected; nothing was changed."
  echo "ddev-docktopus-drupal: to add the docktopus stack modules manually, run:"
  echo "  ddev composer require drush/drush drupal/search_api_solr drupal/ldap"
  touch "$MARKER"
  exit 0
fi

# ------------------------------------------------------------ empty project
if ! grep -q "docroot: web" .ddev/config.yaml 2>/dev/null; then
  echo "ddev-docktopus-drupal: 'docroot: web' is not configured; bootstrap skipped."
  echo "ddev-docktopus-drupal: to create a Drupal site from scratch, run first:"
  echo "  ddev config --project-type=drupal11 --docroot=web"
  echo "ddev-docktopus-drupal: then run 'ddev restart' to trigger the bootstrap."
  exit 0
fi

echo "ddev-docktopus-drupal: empty project detected; creating a Drupal 11 site (this takes a few minutes)..."

ddev composer create-project drupal/recommended-project:^11 --no-interaction
ddev composer require drush/drush drupal/search_api_solr drupal/ldap --no-interaction

# DDEV main database credentials (mariadb/mysql or postgres).
DB_URL="mysql://db:db@db:3306/db"
if grep -q "type: postgres" .ddev/config.yaml; then
  DB_URL="pgsql://db:db@db:5432/db"
fi

ddev drush site:install standard --db-url="$DB_URL" \
  --account-name=admin --account-pass=admin --site-name="Docktopus site" --no-interaction

ddev drush cr
ddev drush en search_api_solr ldap -y

# Connect the stack: Search API Solr server (core "dev") and LDAP server.
if ddev exec drush php:script .ddev/docktopus-drupal/drupal-solr-server.php; then
  echo "ddev-docktopus-drupal: Search API Solr server + index created (backend solr:8983, core dev)."
else
  echo "ddev-docktopus-drupal: WARNING: the Search API Solr server could not be created automatically." >&2
  echo "ddev-docktopus-drupal: create it later at /admin/config/search/search-api/add-server (host: solr, port: 8983, path: /solr, core: dev)." >&2
fi

if ddev exec drush php:script .ddev/docktopus-drupal/drupal-ldap-server.php; then
  echo "ddev-docktopus-drupal: LDAP server entity created (openldap:389, dc=miempresa,dc=local)."
else
  echo "ddev-docktopus-drupal: WARNING: the LDAP server could not be created automatically." >&2
  echo "ddev-docktopus-drupal: create it later at /admin/config/people/ldap." >&2
fi

touch "$MARKER"

echo ""
echo "=== ddev-docktopus-drupal: Drupal 11 site created ==="
echo "  admin user: admin / admin"
echo "  Solr:     /admin/config/search/search-api (server 'solr', index 'default_index')"
echo "  LDAP:     /admin/config/people/ldap (server 'openldap')"
echo "  To finalize DDEV's settings integration, run 'ddev restart' once more."
echo ""
