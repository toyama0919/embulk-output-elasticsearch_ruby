require_relative 'elasticsearch/connection'

module Embulk
  module Output

    class Elasticsearch < OutputPlugin
      Plugin.register_output("elasticsearch_ruby", self)
      ENABLE_MODE = %w[normal update replace]

      def self.transaction(config, schema, count, &control)
        task = {
          "nodes" => config.param("nodes", :array, default: [{ 'host' => 'localhost', 'port' => 9200 }]),
          "request_timeout" => config.param("request_timeout", :integer, default: 60),
          "index_type" => config.param("index_type", :string),
          "mode" => config.param("mode", :string, default: 'normal'),
          "reload_connections" => config.param("reload_connections", :bool, default: true),
          "reload_on_failure" => config.param("reload_on_failure", :bool, default: false),
          "delete_old_index" => config.param("delete_old_index", :bool, default: false),
          "delete_old_alias" => config.param("delete_old_alias", :bool, default: true),
          "id_keys" => config.param("id_keys", :array, default: nil),
          "id_format" => config.param("id_format", :string, default: nil),
          "array_columns" => config.param("array_columns", :array, default: nil),
          "bulk_actions" => config.param("bulk_actions", :integer, default: 1000),
          "retry_on_failure" => config.param("retry_on_failure", :integer, default: 5),
        }

        unless ENABLE_MODE.include?(task['mode'])
          raise ConfigError.new "`mode` must be one of #{ENABLE_MODE.join(', ')}"
        end
        Embulk.logger.info("mode => #{task['mode']}")

        current_index_name = config.param("current_index_name", :string, default: nil)
        index = config.param("index", :string, default: 'logstash-%Y.%m.%d')
        if task['mode'] == 'replace'
          task['alias'] = index
          task['index'] = if current_index_name
            current_index_name
          else
            "#{index}-#{task['index_type']}-#{Time.now.strftime('%Y.%m.%d.%H.%M.%S')}"
          end
        else
          task['index'] = Time.now.strftime(index)
        end
        Embulk.logger.info("nodes => #{task['nodes']}")
        Embulk.logger.info("index => #{task['index']}")
        Embulk.logger.info("index_type => #{task['index_type']}")
        Embulk.logger.info("alias => #{task['alias']}")

        connection = Connection.new(task)
        before_delete_index = config.param("before_delete_index", :bool, default: false)
        if before_delete_index
          connection.delete_index(task['index'])
        end

        before_template_name = config.param("before_template_name", :string, default: nil)
        before_template = config.param("before_template", :hash, default: nil)
        if before_template_name && before_template
          connection.put_template(before_template_name, before_template)
        end

        task_reports = yield(task)
        next_config_diff = {}
        return next_config_diff
      end

      def self.cleanup(task, schema, count, task_reports)
        if task['mode'] == 'replace'
          connection = Connection.new(task)
          connection.create_aliases
          connection.delete_aliases
        end
      end

      #def self.resume(task, schema, count, &control)
      #  task_reports = yield(task)
      #
      #  next_config_diff = {}
      #  return next_config_diff
      #end

      def init
        @connection = Connection.new(task)
        @bulk_actions = task["bulk_actions"]
        @bulk_message = []
      end

      def close
      end

      def add(page)
        page.each do |record|
          hash = Hash[schema.names.zip(record)]
          meta = @connection.generate_meta(hash)
          source = @connection.generate_source(hash)

          Embulk.logger.debug("meta => #{meta}")
          Embulk.logger.debug("source => #{source}")

          @bulk_message << meta
          @bulk_message << source
          if @bulk_actions * 2 <= @bulk_message.size
            @connection.send(@bulk_message)
            @bulk_message.clear
          end
        end
      end

      def finish
        if @bulk_message.size > 0
          @connection.send(@bulk_message)
        end
      end

      def abort
      end

      def commit
        task_report = {}
        return task_report
      end
    end
  end
end
