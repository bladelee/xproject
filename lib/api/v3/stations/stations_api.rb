#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "api/v3/stations/station_collection_representer"
require "api/v3/stations/station_representer"

module API
  module V3
    module Stations
      class StationsAPI < ::API::OpenProjectAPI
        resources :stations do
          after_validation do
            authorize_in_any_work_package(:view_work_packages)
          end

          get do
            StationCollectionRepresenter.new(Station.all,
                                            self_link: nil,
                                            current_user:)
          end

          route_param :id, type: Integer, desc: "Station ID" do
            helpers do
              # Note that naming the method #status or having
              # a variable named @status colides with grape.
              def work_package_station
                Station.find(params[:id])
              end
            end

            get do
              StationRepresenter.new(work_package_station, current_user:)
            end
          end
        end
      end
    end
  end
end
