# Elasticsearch Ruby output plugin for Embulk

Dumps records to Elasticsearch Ruby. Elasticsearch 1.X AND 2.X AND 5.X compatible.

## Overview

* **Plugin type**: output
* **Load all or nothing**: no
* **Resume supported**: no
* **Cleanup supported**: yes

## Configuration
  - **nodes**: nodes (array, default: [{ 'host' => 'localhost', 'port' => 9200 }])
    - **host**: index (string)
    - **port**: index (integer)
  - **request_timeout**: request_timeout (integer, default: 60)
  - **index**: index (string, , default: 'logstash-%Y.%m.%d')
  - **mode**: mode, normal or update or replace (string, default: normal)
  - **reload_connections**: reload_connections (bool, default: true)
  - **reload_on_failure**: reload_on_failure (bool, default: false)
  - **delete_old_index**: delete_old_index (bool, default: false)
  - **index_type**: index_type (string)
  - **id_keys**: id_keys (array, default: nil)
  - **id_format**: id_format (string, default: nil)
  - **array_columns**: array_columns (array, default: nil)
  - **bulk_actions**: bulk_actions (integer, default: 1000)
  - **retry_on_failure**: retry_on_failure (integer, default: 5)

## Example

```yaml
out:
  type: elasticsearch_ruby
  nodes:
    - {host: localhost, port: 9200}
  index_type: page
```

## Example(update)

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
