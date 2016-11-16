# Elasticsearch Ruby output plugin for Embulk

Dumps records to Elasticsearch Ruby. Elasticsearch 1.X AND 2.X compatible.

## Overview

* **Plugin type**: output
* **Load all or nothing**: no
* **Resume supported**: no
* **Cleanup supported**: yes

## Configuration
  - **nodes**: nodes (array)
    - **host**: index (string)
    - **port**: index (integer)
  - **request_timeout**: request_timeout (integer, default: 60)
  - **index**: index (string)
  - **mode**: mode (string, normal or update or replace])
  - **reload_connections**: reload_connections (bool, default: true)
  - **reload_on_failure**: reload_on_failure (bool, default: false)
  - **delete_old_index**: delete_old_index (bool, default: false)
  - **index_type**: index_type (string)
  - **id_keys**: id_keys (array, default: nil)
  - **id_format**: id_format (string, default: nil)
  - **array_columns**: array_columns (array, default: nil)
  - **bulk_actions**: bulk_actions (integer, default: 1000)
  - **retry_on_failure**: retry_on_failure (integer, default: 5)
  - **time_key**: time_key (string, default: nil)

## Example

```yaml
out:
  type: elasticsearch_ruby
  nodes:
    - {host: {{ env.ES_HOST }}, port: 9200}
  index: crawl
  index_type: page
  bulk_actions: 1000
  request_timeout: 60
  mode: update
  id_format: "%s"
  id_keys:
    - _id
```


## Build

```
$ rake
```
