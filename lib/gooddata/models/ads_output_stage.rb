# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'

module GoodData
  class AdsOutputStage < Rest::Resource
    OUTPUT_STAGE_PATH = '/gdc/dataload/projects/%s/outputStage'

    attr_accessor :client_id, :output_stage_prefix, :schema

    class << self
      def [](opts = { client: GoodData.connection, project: GoodData.project })
        c, project = GoodData.get_client_and_project(opts)
        uri = OUTPUT_STAGE_PATH % project.pid
        data = c.get(uri)
        c.create(AdsOutputStage, data, opts)
      end

      def create(opts = { client: GoodData.connection })
        c = GoodData.get_client(opts)

        [:project, :ads].each do |key|
          fail "No #{key.inspect} specified" unless opts[key]
        end

        schema = (opts[:ads].respond_to?(:schemas) && opts[:ads].schemas) || opts[:ads]

        schema += '/default' unless schema.end_with?('/default')

        json = {
          'outputStage' => {
            'schema' => schema
          }
        }

        output_stage = c.create(AdsOutputStage, json, opts)
        output_stage.save
        output_stage
      end
    end

    def initialize(json)
      super
      @json = json

      @schema = data['schema']
      @client_id = data['clientId']
      @output_stage_prefix = data['outputStagePrefix']
    end

    def sql_diff
      res = client.get "#{build_output_stage_path}/sqlDiff"
      ret = client.poll_on_response(res['asyncTask']['link']['poll']) { |body| body['asyncTask'] }
      ret.freeze
    end

    def save
      data_to_send = GoodData::Helpers.deep_dup(raw_data).tap do |d|
        d['outputStage']['clientId'] = client_id if client_id
        d['outputStage']['outputStagePrefix'] = output_stage_prefix if output_stage_prefix
        d['outputStage']['schema'] = schema
      end

      url = build_output_stage_path
      @json = client.put(url, data_to_send, accept: 'application/json; version=1')
    end

    def delete
      data_to_send = { 'outputStage' => { 'clientId' => '', 'outputStagePrefix' => '' } }
      url = build_output_stage_path
      @json = client.put(url, data_to_send, accept: 'application/json; version=1')
    end

    private

    def build_output_stage_path
      pid = (project.respond_to?(:pid) && project.pid) || project
      OUTPUT_STAGE_PATH % pid
    end
  end
end
