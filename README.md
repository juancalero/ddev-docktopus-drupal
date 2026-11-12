[![tests](https://github.com/juancalero/ddev-docktopus-drupal/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/juancalero/ddev-docktopus-drupal/actions/workflows/tests.yml)
[![release](https://img.shields.io/github/v/release/juancalero/ddev-docktopus-drupal)](https://github.com/juancalero/ddev-docktopus-drupal/releases/latest)

# DDEV Docktopus Drupal

Makes the [ddev-docktopus](https://github.com/juancalero/ddev-docktopus) stack work on **both** kinds of projects:

- **From scratch**: on the next `ddev restart`, an empty project is bootstrapped automatically into a **Drupal 11** site — `composer create-project drupal/recommended-project`, `drush site:install`, and the docktopus stack modules (`search_api_solr`, `ldap`) installed, enabled and connected (Search API Solr server + index on the `dev` core, LDAP server entity against OpenLDAP).
- **Existing**: a project with code is detected and **left untouched**; the add-on just prints how to add the stack modules if you want them.

It does this through a `config.ddev-docktopus-drupal.yaml` file whose `post-start` hook runs an idempotent bootstrap script on every `ddev restart` (DDEV merges hooks from `config.*.yaml` files, so your `config.yaml` is never modified).

> Part of [ddev-docktopus](https://github.com/juancalero/ddev-docktopus) — the meta add-on that installs the whole docktopus stack with one command.

## From scratch

```
mkdir my-site && cd my-site
ddev config --project-type=drupal11 --docroot=web
ddev start
ddev add-on get juancalero/ddev-docktopus-drupal    # or the meta add-on
ddev restart
```

The bootstrap runs during that `restart` and takes a few minutes (composer + site install). When it finishes:

| | |
| --- | --- |
| Site | `https://<project>.ddev.site` |
| Admin | `admin` / `admin` |
| Solr | `/admin/config/search/search-api` — server `solr` (host `solr`, core `dev`) + index `Content` |
| LDAP | `/admin/config/people/ldap` — server `openldap` (`openldap:389`, base DN `dc=miempresa,dc=local`) |
| Modules required | `drush/drush`, `drupal/search_api_solr`, `drupal/ldap` |

Run `ddev restart` once more afterwards to finalize DDEV's settings-file integration (Mailpit, etc.).

## Decision table (every `ddev restart`)

| State | What happens |
| --- | --- |
| `.ddev/docktopus-drupal/.installed` exists | nothing (silent) |
| `.ddev/docktopus-drupal/.skip` exists | nothing (silent) |
| `composer.json` exists (existing project) | nothing is changed; marks itself done |
| empty project, `docroot: web` set | **full bootstrap** (once) |
| empty project, `docroot: web` missing | prints the setup instructions, changes nothing |

## Opting out

```
touch .ddev/docktopus-drupal/.skip
```

## Configuration

- Drupal version: `^11` (hardcoded in the bootstrap — edit `.ddev/docktopus-drupal/bootstrap.sh` to change it).
- Admin credentials: `admin` / `admin` (same bootstrap script).
- Database: DDEV's main database (MariaDB/MySQL by default, or Postgres if that is the project's `database.type`).

## Uninstallation

```
ddev add-on remove ddev-docktopus-drupal
ddev restart
```

The hook and the bootstrap files are removed. The Drupal site itself — if the add-on created it — is your project code and is kept.

## License

GPL-2.0-or-later
