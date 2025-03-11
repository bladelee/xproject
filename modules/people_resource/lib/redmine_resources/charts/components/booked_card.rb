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
      class BookedCard < BaseCard
        def initialize(date, issue, project, resource_booking, time_entries, is_workday)
          super(date, issue, project, resource_booking, time_entries)

          @planned_hours = @resource_booking.hours_per_day
          @progress_bar = BookedCardProgressBar.new(@date, @issue, @project, @spent_hours, @planned_hours)
          @description_box_height = CARD_HEIGHT_COEFFICIENT * [@planned_hours, 24].min
          @is_workday = is_workday
          @workday_length = to_int_if_whole(RedmineResources.default_workday_length)
          @workload_percent  = @planned_hours * 100 / @workday_length
        end

        def render
          <<-HTML.html_safe
            <div class="booking-card #{'dayoff' if dayoff?} #{'ending' if @issue && @issue.due_date == @date} booking">
              <p class="project-name" style="display: block;">#{h(@project)}</p>
              <div class="issue-id tooltip">
                <span class="tip issue-spent">
                  #{render_resource_booking_tooltip(@resource_booking)}
                </span>
                <strong>#{render_card_heading}</strong>
                <span class="hours">#{I18n.t(:label_resources_f_hour_short, value: to_int_if_whole(@planned_hours))}</span>
              </div>
              <div class="description-box#{'-dayoff' if dayoff?}" style="height: #{@description_box_height}em;">
                <div class="text-box">
                  #{@description}
                </div>
              </div>
              #{@progress_bar.render}
            </div>
          HTML
        end

        def small_block_render(show_hours)
          <<-HTML.html_safe
            <div class="small-booking-card#{'-dayoff' if dayoff?}#{'-part-dayoff' if part_dayoff?} editable booking tooltip" edit_url="#{edit_path_for(@resource_booking)}">
              <span class="tip issue-spent">
                #{render_resource_booking_tooltip(@resource_booking)}
              </span>
              <p class="hours">#{I18n.t(:label_resources_f_hour_short, value: to_int_if_whole(@planned_hours))}</p>
              <p class="percent">#{render_percent}</p>
            </div>
          HTML
        end

        private

        def dayoff?
          @is_workday == 'dayoff'
        end

        def part_dayoff?
          @is_workday == 'part_dayoff'
        end

        def render_percent
          "#{@workload_percent.round(2)}%" unless dayoff?
        end
      end
    end
  end
end
