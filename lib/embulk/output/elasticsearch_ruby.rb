require 'excon'
require 'elasticsearch'

module Embulk
  module Output

    class ElasticsearchRuby < OutputPlugin
      Plugin.register_output("elasticsearch_ruby", self)

      def self.transaction(config, schema, count, &control)
        task = {
          "nodes" => config.param("nodes", :array),
          "request_timeout" => config.param("request_timeout", :integer, default: 60),
          "index" => config.param("index", :string),
          "replace_mode" => config.param("replace_mode", :bool, default: false),
          "reload_connections" => config.param("reload_connections", :bool, default: true),
          "reload_on_failure" => config.param("reload_on_failure", :bool, default: false),
          "delete_old_index" => config.param("delete_old_index", :bool, default: false),
          "index_type" => config.param("index_type", :string),
          "id_keys" => config.param("id_keys", :array, default: nil),
          "id_format" => config.param("id_format", :string, default: nil),
          "array_columns" => config.param("array_columns", :array, default: nil),
          "bulk_actions" => config.param("bulk_actions", :integer, default: 1000),
          "retry_on_failure" => config.param("retry_on_failure", :integer, default: 5),
          "time_key" => config.param("id_format", :string, default: nil),
        }
        task['time_value'] = Time.now.strftime('%Y.%m.%d.%H.%M.%S')

        task_reports = yield(task)
        next_config_diff = {}
        return next_config_diff
      end

      #def self.resume(task, schema, count, &control)
      #  task_reports = yield(task)
      #
      #  next_config_diff = {}
      #  return next_config_diff
      #end

      def init
        @nodes = task["nodes"]
        @index_type = task["index_type"]
        @id_keys = task["id_keys"]
        @id_format = task["id_format"]
        @bulk_actions = task["bulk_actions"]
        @request_timeout = task["request_timeout"]
        @reload_connections = task["reload_connections"]
        @reload_on_failure = task["reload_on_failure"]
        @array_columns = task["array_columns"]
        @retry_on_failure = task["retry_on_failure"]
        @delete_old_index = task["delete_old_index"]
        @replace_mode = task["replace_mode"]
        @alias = task["index"]
        @index_prefix = "#{task['index']}-#{task['index_type']}"
        if @replace_mode
          @index = "#{@index_prefix}-#{task['time_value']}"
        else
          @index = task['index']
        end

        @nodes =@nodes.map do |node|
          Hash[node.map{ |k, v| [k.to_sym, v] }]
        end
        transport = Elasticsearch::Transport::Transport::HTTP::Faraday.new(
          {
            hosts: @nodes,
            options: {
              reload_connections: @reload_connections,
              reload_on_failure: @reload_on_failure,
              retry_on_failure: @retry_on_failure,
              transport_options: {
                request: { timeout: @request_timeout }
              }
            }
          }
        )

        @client = Elasticsearch::Client.new transport: transport
        @bulk_message = []
      end

      def close
      end

      def add(page)
        page.each do |record|
          hash = Hash[schema.names.zip(record)]
          meta = { index: { _index: @index, _type: @index_type } }
          meta[:index][:_id] = generate_id(@id_format, hash, @id_keys) unless @id_keys.nil?
          source = generate_array(hash)
          @bulk_message << meta
          @bulk_message << source
          if @bulk_actions * 2 <= @bulk_message.size
            send
          end
        end
      end

      def finish
        if @bulk_message.size > 0
          send
        end
      end

      def abort
      end

      def commit
        if @replace_mode
          create_aliases(@alias, @index)
          delete_aliases
        end

        task_report = {}
        return task_report
      end

      private

      def generate_array(record)
        result = {}
        record.each { |key, value|
          result[key] = value
          next unless @array_columns
          @array_columns.each do |array_column|
            if array_column['name'] == key
              array_value = value.split(array_column['delimiter']).reject(&:empty?)
              array_value = array_value.map(&:to_i) if array_column['is_integer']
              result[key] = array_value
            end
          end
        }
        result
      end

      def generate_id(template, record, id_keys)
        template % id_keys.map { |key| record[key] }
      end

      def send
        retries = 0
        begin
          @client.bulk body: @bulk_message
          Embulk.logger.info "bulk: #{@bulk_message.size/2} success."
        rescue *@client.transport.host_unreachable_exceptions => e
          if retries < @retry_on_failure
            retries += 1
            Embulk.logger.warn "Could not push logs to Elasticsearch, resetting connection and trying again. #{e.message}"
            sleep 2**retries
            retry
          end
          raise "Could not push logs to Elasticsearch after #{retries} retries. #{e.message}"
        end
        @bulk_message.clear
      end

      def create_aliases(als, index)
        @client.indices.update_aliases body: {
          actions: [{ add: { index: index, alias: als } }]
        }
        Embulk.logger.info "created alias: #{als}, index: #{index}"
      end

      def delete_aliases
        indices = @client.indices.get_aliases.select { |key, value| value['aliases'].include? @alias }.keys
        indices = indices.select { |index| /^#{@index_prefix}-(\d*)/ =~ index }
        indices.each { |index|
          if index != @index
            @client.indices.delete_alias index: index, name: @alias
            Embulk.logger.info "deleted alias: #{@alias}, index: #{index}"
            if @delete_old_index
              @client.indices.delete index: index
              Embulk.logger.info "deleted index: #{index}"
            end
          end
        }
      end
    end
  end
end
