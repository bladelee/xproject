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
      class WorkloadCard < BaseComponent
        def initialize(is_workday, resource_bookings, time_entries, workday_length)
          @is_workday = is_workday
          @resource_bookings = resource_bookings
          @time_entries = time_entries
          @planned_hours = to_int_if_whole(@resource_bookings.sum(&:hours_per_day))
          @workday_length = to_int_if_whole(workday_length)
          @workload_percent  = @planned_hours * 100 / @workday_length
          @spent_hours = to_int_if_whole(@time_entries.sum(&:hours))
        end

        def render
          if @is_workday || @spent_hours > 0
            <<-HTLM.html_safe
              <div class="workload-card #{color_css_class}">
                <div class="spent spent-time" style="display: block;">
                #{I18n.t(:label_resources_f_hour_short, value: @spent_hours)}
                </div>
                <div class="tooltip">
                  #{html_tooltip_for_user}
                  #{render_planned_hours_and_workday_length_ratio if @is_workday}
                </div>
              </div>
            HTLM
          end
        end

        def render_percent_workload
          if @is_workday || @spent_hours > 0
            <<-HTLM.html_safe
              <div class="workload-card #{color_css_class_for_percent_workload}">
                <div class="spent spent-time" style="display: block;">
                  #{I18n.t(:label_resources_f_hour_short, value: @spent_hours)}
                </div>
                <div class="tooltip">
                  #{html_tooltip_for_user}
                  #{render_workload_percent_and_workday_length_ratio if @is_workday}
                </div>
              </div>
            HTLM
          end
        end

        def render_for_utilization_report(show_spent_time, show_percent, show_hours)
          if @is_workday || @spent_hours > 0
            <<-HTLM.html_safe
              <div class="workload-card #{color_css_class}">
                #{render_spent_time if show_spent_time}
                <div class="tooltip">
                  #{render_planned_hours_and_workday_length_ratio if show_hours}
                  <div class="percent">
                    #{render_workload_percent if @is_workday && show_percent}
                  </div>
                  #{html_tooltip_for_user}
                </div>
              </div>
            HTLM
          end
        end

        private

        def render_planned_hours_and_workday_length_ratio
          "<p>#{@planned_hours}/#{@workday_length}</p>"
        end

        def render_workload_percent_and_workday_length_ratio
          "<p>#{@workload_percent}%/#{@workday_length}</p>"
        end

        def render_workload_percent
          "#{@workload_percent}%"
        end

        def render_spent_time
          if @time_entries.present?
            time_entries_filter = { set_filter: '1', user_id: @time_entries.first.user_id, spent_on: @time_entries.first.spent_on }

            "<div class='spent-time'>
              #{link_to(I18n.t(:label_resources_f_hour_short, value: @spent_hours), time_entries_path(time_entries_filter), style: 'color: white;')}
            </div>"
          else
            "<div class='spent-time'>
              #{I18n.t(:label_resources_f_hour_short, value: @spent_hours)}
            </div>"
          end
        end

        def html_tooltip_for_user
          s = render_load_tooltip(@workday_length - @planned_hours, @workday_length)
          s = content_tag(:span, s.html_safe, class: 'tip')
        end

        def color_css_class
          if !@is_workday
            'gray'
          elsif @planned_hours == @workday_length
            'full'
          elsif @planned_hours > @workday_length
            'red'
          else
            'green'
          end
        end

        def color_css_class_for_percent_workload
          if !@is_workday
            'gray'
          elsif @workload_percent < 95
            'green'
          elsif @workload_percent > 100
            'red'
          else
            'full'
          end
        end
      end
    end
  end
end
