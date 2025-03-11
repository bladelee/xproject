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

class ResourceBookingQuery < ResourceQuery
  include Redmine::Utils::DateCalculation

  ALLOCATION_CHART = 'allocation_chart'.freeze
  UTILIZATION_REPORT = 'utilization_report'.freeze
  attr_accessor :pro
  CHART_TYPES = [ALLOCATION_CHART, UTILIZATION_REPORT].freeze

  # self.queried_class = ResourceBooking

  def base_scope
    scope = ResourceBooking.visible.joins(:project)
    scope.joins(:assigned_to).includes(:work_package).where(statement)
  end

  def resource_bookings_between(from, to)
    scope = base_scope.between(from, to)
    Rails.logger.debug scope.to_sql
    scope
  end

  # def resource_bookings_between(from, to)
  #   base_scope.between(from, to)
  # end

  def resource_bookings_by_users(from, to)
    scope = ResourceBooking.between(from, to)
    if has_filter?('assigned_to_id')
      scope = scope.where(sql_by_filter('assigned_to_id', ResourceBooking.table_name, 'assigned_to_id'))
    end
    scope
  end

  def chart_bookings(from, to)
      resource_bookings_between(from, to)
  end

  def chart_type=(arg)
    if CHART_TYPES.include?(arg)
      options[:chart_type] = arg
    else
      raise ArgumentError.new("value must be one of: #{CHART_TYPES.join(', ')}")
    end
  end

  def allocation_chart?
    chart_type == ALLOCATION_CHART
  end

  def utilization_report?
    chart_type == UTILIZATION_REPORT
  end

  def chart_class
    #  RedmineResources::Charts::AllocationChart
    RedmineResources::Charts::UtilizationReportChart
  end

  def group_by_project?
    true
    # group_by == PROJECT_GROUP
  end

  def group_by_user?
    true
    # group_by == USER_GROUP
  end

  def date_from; options[:date_from] end
  def date_from=(arg); options[:date_from] = arg.to_date end

  def build_from_params(params)
    super
    self.show_project_names = params[:show_project_names] || (params[:query] && params[:query][:show_project_names]) || '1'
    self.show_spent_time = params[:show_spent_time] || (params[:query] && params[:query][:show_spent_time])
    chart_name = params[:chart_type] || (params[:query] && params[:query][:chart_type]) || ALLOCATION_CHART
    self.chart_type = chart_name == 'issues_chart' ? ALLOCATION_CHART : chart_name

    if params[:year] && params[:month]
      self.date_from = "#{params[:year]}-#{params[:month]}-01".to_date
    elsif params[:zoom] && self.chart_type == ALLOCATION_CHART && (params[:zoom] == 1 || params[:zoom] == 2)
      User.current.today.at_beginning_of_month
    else
      self.date_from = params[:date_from].presence || (params[:query] && params[:query][:date_from].presence) || RedmineResources.beginning_of_week
    end

    self
  end

  private

  # def available_issues(from, to)
  #   scope =
  #     Issue.visible(User.current, project: project).open
  #       .joins(:assigned_to)
  #       .where(due_date: from..to.next_day(7))
  #       .where("#{Issue.table_name}.done_ratio < 100")
  #   scope = scope.joins(:project).where(project_id: EnabledModule.where(name: 'resources').pluck(:project_id))

  #   %w(assigned_to_id project_id).each do |field|
  #     scope = scope.where(sql_by_filter(field, Issue.table_name, field)) if has_filter?(field)
  #   end

  #   scope = scope.where(sql_by_filter('issue_id', Issue.table_name, 'id')) if has_filter?('issue_id')
  #   scope
  # end

  def line_title_types
    RedmineResources::Charts::AllocationChart::LINE_TITLE_TYPES
  end

  def default_line_title_type
    RedmineResources::Charts::AllocationChart::TOTAL_HOURS
  end
end
