# Elasticsearch Ruby output plugin for Embulk

[![Gem Version](https://badge.fury.io/rb/embulk-output-elasticsearch_ruby.svg)](http://badge.fury.io/rb/embulk-output-elasticsearch_ruby)
[![Build Status](https://secure.travis-ci.org/toyama0919/embulk-output-elasticsearch_ruby.png?branch=master)](http://travis-ci.org/toyama0919/embulk-output-elasticsearch_ruby)

Dumps records to Elasticsearch Ruby. Elasticsearch 1.X AND 2.X AND 5.X compatible.

## Overview

* **Plugin type**: output
* **Load all or nothing**: no
* **Resume supported**: no
* **Cleanup supported**: yes

## Configuration
- **nodes** nodes (array, default: [{ 'host' => 'localhost', 'port' => 9200 }])
    - **host** host (string)
    - **port** port (string)
- **request_timeout** request timeout (integer, default: 60)
- **index_type** index type (string)
- **mode** mode (string, default: 'normal')
- **reload_connections** reload connections (bool, default: true)
- **reload_on_failure** reload on failure (bool, default: false)
- **delete_old_index** delete old index (bool, default: false)
- **delete_old_alias** delete old alias (bool, default: true)
- **id_keys** id keys (array, default: nil)
- **id_format** id format (string, default: nil)
- **array_columns** array columns (array, default: nil)
- **bulk_actions** bulk actions (integer, default: 1000)
- **retry_on_failure** retry on failure (integer, default: 5)
- **current_index_name** current index name (string, default: nil)
- **index** index (string, default: 'logstash-%Y.%m.%d')
- **before_delete_index** before delete index (bool, default: false)
- **before_template_name** before template name (string, default: nil)
- **before_template** before template (hash, default: nil)

## Example(minimum settings)

```yaml
out:
  type: elasticsearch_ruby
  nodes:
    - {host: localhost, port: 9200}
  index_type: page
```

## Example(update mode)

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

## Example(replace mode)

```yaml
out:
  type: elasticsearch_ruby
  nodes:
    - {host: localhost, port: 9200}
  index: test_alias
  index_type: crawl_companies
  mode: replace
  delete_old_index: true
  before_delete_index: true
  bulk_actions: 1000
  request_timeout: 60
```

* create alias 

## Build

```
$ rake
```
