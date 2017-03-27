require 'excon'
require 'elasticsearch'

module Embulk
  module Output
    class Elasticsearch < OutputPlugin
      class Connection
        def initialize(task)
          @nodes = task["nodes"]
          @index_type = task["index_type"]
          @id_keys = task["id_keys"]
          @id_format = task["id_format"]
          @array_columns = task["array_columns"]
          @retry_on_failure = task["retry_on_failure"]
          @mode = task["mode"]
          @delete_old_index = task['delete_old_index']
          @delete_old_alias = task['delete_old_alias']
          @index = task['index']
          @alias = task['alias']
          @action = (@mode == 'update') ? :update : :index

          @client = create_client(
            nodes: task['nodes'],
            reload_connections: task['reload_connections'],
            reload_on_failure: task['reload_on_failure'],
            retry_on_failure: task['retry_on_failure'],
            request_timeout: task['request_timeout']
          )
        end

        def create_client(nodes: ,reload_connections: ,reload_on_failure: ,retry_on_failure: ,request_timeout:)
          transport = ::Elasticsearch::Transport::Transport::HTTP::Faraday.new(
            {
              hosts: nodes.map{ |node| Hash[node.map{ |k, v| [k.to_sym, v] }] },
              options: {
                reload_connections: reload_connections,
                reload_on_failure: reload_on_failure,
                retry_on_failure: retry_on_failure,
                transport_options: {
                  request: { timeout: request_timeout }
                }
              }
            }
          )
          ::Elasticsearch::Client.new transport: transport
        end

        def put_template(before_template_name, before_template)
          Embulk.logger.info("put template => #{before_template_name}")
          @client.indices.put_template name: before_template_name, body: before_template
        end

        def create_aliases
          @client.indices.update_aliases body: {
            actions: [{ add: { index: @index, alias: @alias } }]
          }
          Embulk.logger.info "created alias: #{@alias}, index: #{@index}"
        end

        def delete_aliases
          indices = @client.indices.get_alias(name: @alias).keys
          indices.each do |index|
            if index != @index
              if @delete_old_alias
                @client.indices.delete_alias index: index, name: @alias
                Embulk.logger.info "deleted alias: #{@alias}, index: #{index}"
              end
              if @delete_old_index
                delete_index(index)
              end
            end
          end
        end

        def delete_index(index)
          indices = @client.cat.indices(format: 'json')
          if indices.any? { |i| i['index'] == index }
            @client.indices.delete index: index
            Embulk.logger.info "deleted index: #{index}"
          end
        end

        def send(bulk_message)
          retries = 0
          begin
            @client.bulk body: bulk_message
            Embulk.logger.info "bulk: #{bulk_message.size/2} success."
          rescue => e
            if retries < @retry_on_failure
              retries += 1
              Embulk.logger.warn "Could not push logs to Elasticsearch, resetting connection and trying again. #{e.message}"
              sleep 2**retries
              retry
            end
            raise "Could not push logs to Elasticsearch after #{retries} retries. #{e.message}"
          end
        end

        def generate_source(record)
          result = {}

          record.each { |key, value|
            result[key] = value
            next if (value.nil? || !@array_columns)
            @array_columns.each do |array_column|
              if array_column['name'] == key
                array_value = value.split(array_column['delimiter']).reject(&:empty?)
                array_value = array_value.map(&:to_i) if array_column['is_integer']
                result[key] = array_value
              end
            end
          }
          (@mode == 'update') ? {doc: result} : result
        end

        def generate_id(template, record, id_keys)
          template % id_keys.map { |key| record[key] }
        end

        def generate_meta(record)
          meta = {}
          meta[@action] = { _index: @index, _type: @index_type }
          meta[@action][:_id] = generate_id(@id_format, record, @id_keys) unless @id_keys.nil?
          meta
        end
      end
    end
  end
end
