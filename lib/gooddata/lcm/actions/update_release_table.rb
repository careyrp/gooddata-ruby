# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class UpdateReleaseTable < BaseAction
      DESCRIPTION = 'Update Release Table'

      PARAMS = define_params(self) do
        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: true
      end

      DEFAULT_TABLE_NAME = 'LCM_RELEASE'

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          domain_name = params.organization || params.domain
          client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          params.segments.map do |segment_in|
            segment_id = segment_in.segment_id

            placeholders = {
              segment_id: segment_in[:segment_id],
              master_project_id: segment_in[:master_pid],
              version: segment_in[:version],
              timestamp: segment_in[:timestamp],
              table_name: params.release_table_name || DEFAULT_TABLE_NAME
            }

            update_release_table(params, placeholders)

            {
              segment: segment_id,
              master_pid: segment_in[:master_pid],
              version: segment_in[:version],
              timestamp: segment_in[:timestamp]
            }
          end
        end

        def update_release_table(params, placeholders)
          query = if placeholders[:version] > 1
                    path = File.expand_path('../../data/update_lcm_release.sql.erb', __FILE__)
                    default_query = GoodData::Helpers::ErbHelper.template_file(path, placeholders)

                    (params.query && params.query.update) || default_query
                  else
                    path = File.expand_path('../../data/insert_into_lcm_release.sql.erb', __FILE__)
                    default_query = GoodData::Helpers::ErbHelper.template_file(path, placeholders)

                    (params.query && params.query.insert) || default_query
                  end

          params.ads_client.execute(query)
        end
      end
    end
  end
end
