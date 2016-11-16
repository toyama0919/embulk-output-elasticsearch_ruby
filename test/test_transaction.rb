require_relative './helper'
require 'embulk/output/elasticsearch_ruby'

OUTPUT_ELASTICSEARCH = Embulk::Output::Elasticsearch

module Embulk
  class Output::Elasticsearch
    class TestTransaction < Test::Unit::TestCase
      def least_config
        DataSource.new({
          'nodes'     => [{ 'host' => 'localhost', 'port' => 9200 }],
          'index_type' => 'page'
        })
      end

      def schema
        Schema.new([
          Column.new({index: 0, name: 'boolean', type: :boolean}),
          Column.new({index: 1, name: 'long', type: :long}),
          Column.new({index: 2, name: 'double', type: :double}),
          Column.new({index: 3, name: 'string', type: :string}),
          Column.new({index: 4, name: 'timestamp', type: :timestamp}),
          Column.new({index: 5, name: 'json', type: :json}),
        ])
      end

      def processor_count
        1
      end

      def control
        Proc.new {|task| task_reports = [] }
      end

      def setup
        stub(OUTPUT_ELASTICSEARCH).transaction_report { {} }
      end

      sub_test_case "normal" do
        def test_minimum
          config = least_config
          OUTPUT_ELASTICSEARCH.transaction(config, schema, processor_count, &control)
        end

        def test_mode
          config = least_config.merge('mode' => 'update')
          OUTPUT_ELASTICSEARCH.transaction(config, schema, processor_count, &control)

          config = least_config.merge('mode' => 'replace')
          OUTPUT_ELASTICSEARCH.transaction(config, schema, processor_count, &control)
        end
      end

      sub_test_case "error" do
        def test_mode
          config = least_config.merge('mode' => 'hoge')
          assert_raise ConfigError do
            OUTPUT_ELASTICSEARCH.transaction(config, schema, processor_count, &control)
          end
        end
      end
    end
  end
end
