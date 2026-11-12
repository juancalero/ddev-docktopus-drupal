#!/usr/bin/env bats

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=juancalero/ddev-docktopus-drupal

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  export CI=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-type=drupal11 --docroot=web
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # The bootstrap must have run and marked itself as done.
  assert_file_exist .ddev/docktopus-drupal/.installed

  # Drupal must be installed and reachable.
  run ddev exec drush status --fields=bootstrap,drush-version
  assert_success
  assert_output --partial "Successful"

  # The stack modules must be enabled and the Solr server connected.
  run ddev exec drush pml --status=enabled --format=list
  assert_success
  assert_output --partial "search_api_solr"
  assert_output --partial "ldap_servers"

  run ddev exec drush php:eval "print count(\Drupal::entityTypeManager()->getStorage('search_api_server')->loadMultiple());"
  assert_output --partial "1"

  run ddev exec drush php:eval "print count(\Drupal::entityTypeManager()->getStorage('ldap_server')->loadMultiple());"
  assert_output --partial "1"

  # The site must answer through Varnish.
  run curl -sfI "https://${PROJNAME}.ddev.site"
  assert_success
  assert_output --partial "200"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory (bootstraps a Drupal site)" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release (bootstraps a Drupal site)" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
