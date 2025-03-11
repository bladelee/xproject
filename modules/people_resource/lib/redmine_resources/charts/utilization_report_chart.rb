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
    class UtilizationReportChart
      attr_accessor :view, :months

      def initialize(project, query, _options = {})
        raise ArgumentError unless query

        @project = project
        @query = query
      end

      def common_params
        { controller: 'resource_bookings_controller', action: 'index', project_id: @project }
      end

      def params
        common_params.merge(date_from: date_from)
      end

      def empty?
        resource_bookings.empty? && time_entries.empty?
      end

      def user_schedules
        if @query.group_by_project?
          build_user_schedules
        else # group by issue
          build_user_schedules
        end
      end

      private

      def date_from
        @date_from ||= @query.date_from
      end

      def date_to
        @date_to ||= @query.date_from.end_of_month
      end

      def resource_bookings
        @resource_bookings ||= @query.resource_bookings_between(date_from, date_to).to_a
      end

      def time_entries
        @time_entries ||= begin
          scope = TimeEntry.includes(:project, :work_package, :activity, :user)
          if @project
            scope = scope.references(:project)
              .where("#{Project.table_name}.lft >= #{@project.lft} AND #{Project.table_name}.rgt <= #{@project.rgt}")
          end
          scope.where('spent_on BETWEEN ? AND ?', date_from, date_to).to_a
        end
      end

      def resource_bookings_groups_by_user_id
        @resource_bookings_groups_by_user_id ||= resource_bookings.group_by(&:assigned_to_id)
      end

      def time_entries_groups_by_user_id
        @time_entries_groups_by_user_id ||= time_entries.group_by(&:user_id)
      end

      def projects
        @projects ||= (resource_bookings.map(&:project) + time_entries.map(&:project)).uniq(&:id)
      end

      def users
        user_ids = resource_bookings.map(&:assigned_to_id) | time_entries.map(&:user_id)
        @users ||= User.where(id: user_ids)
      end

      def build_user_schedules
        users.map do |user|
          Helpers::UserSchedule.new(
            user,
            date_from,
            date_to,
            resource_bookings_groups_by_user_id[user.id].to_a,
            time_entries_groups_by_user_id[user.id].to_a)
        end
      end

    end
  end
end
