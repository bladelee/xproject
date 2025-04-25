# This file is a part of Redmine Resources (redmine_resources) plugin,
# resource allocation and management for Redmine
#
# Copyright (C) 2011-2024 RedmineUP
# http://www.redmineup.com/
#
# redmine_resources is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_resources is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_resources.  If not, see <http://www.gnu.org/licenses/>.

module RedmineResources
  module Charts
    module Components
      class ProjectPlanCard < BaseComponent
        def initialize(is_workday, allocated_hours, workday_length)
          @is_workday = is_workday
          @planned_hours = allocated_hours
          @workday_length = workday_length
          @workload_percent = @planned_hours * 100 / @workday_length
        end

        def render
          if @is_workday && @planned_hours > 0

          # <p class="hours">#{I18n.t(:label_resources_f_hour_short, value: @planned_hours)}</p>           
            <<-HTML.html_safe
              <div class="small-booking-card booking">
                <p class="hours">#{@planned_hours}</p>
                <p class="percent">#{@workload_percent}%</p>
              </div>
            HTML
          end
        end
      end
    end
  end
end
