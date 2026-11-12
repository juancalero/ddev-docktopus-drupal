<?php
// Creates the Search API Solr server and a content index connected to the
// DDEV "dev" Solr core (ddev-docktopus-config, Solr 9). Idempotent:
//ddev-generated

use Drupal\search_api\Entity\Index;
use Drupal\search_api\Entity\Server;

if (!\Drupal::moduleHandler()->moduleExists('search_api_solr')) {
  echo "search_api_solr is not enabled; skipping.\n";
  exit(0);
}

$storage = \Drupal::entityTypeManager()->getStorage('search_api_server');

// ---- Server ------------------------------------------------------------
if ($storage->loadByProperties(['id' => 'solr'])) {
  echo "server 'solr' already exists.\n";
}
else {
  Server::create([
    'id' => 'solr',
    'name' => 'Solr (docktopus)',
    'description' => 'Solr 9 core "dev" provided by ddev-docktopus-config.',
    'status' => TRUE,
    'backend' => 'search_api_solr',
    'backend_config' => [
      'connector' => 'standard',
      'connector_config' => [
        'scheme' => 'http',
        'host' => 'solr',
        'port' => 8983,
        'path' => '/solr',
        'core' => 'dev',
        'commit_within' => 1000,
      ],
      'retrieve_data' => TRUE,
      'highlight_data' => FALSE,
      'http_timeout' => 300,
    ],
  ])->save();
  echo "server 'solr' created.\n";
}

// ---- Index -------------------------------------------------------------
$index_storage = \Drupal::entityTypeManager()->getStorage('search_api_index');
if ($index_storage->loadByProperties(['id' => 'default_index'])) {
  echo "index 'default_index' already exists.\n";
}
else {
  Index::create([
    'id' => 'default_index',
    'name' => 'Content',
    'description' => 'Content index on the Solr (docktopus) server.',
    'status' => TRUE,
    'server' => 'solr',
    'datasource_settings' => [
      'entity:node' => [
        'plugin_id' => 'entity:node',
        'settings' => [],
      ],
    ],
    'tracker_settings' => [
      'default' => [
        'plugin_id' => 'default',
        'settings' => [],
      ],
    ],
  ])->save();
  echo "index 'default_index' created.\n";
}

echo "Add fields to the index and enable it at /admin/config/search/search-api.\n";
