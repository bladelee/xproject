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

class ResourceQuery < Query
  include Redmine::Utils::DateCalculation

  HOURS = 'hours'.freeze
  PERCENTS = 'percent'.freeze
  WORKLOAD_TYPES = [HOURS, PERCENTS].freeze

   
  attr_accessor :options
  # self.view_permission = :view_resources

  def initialize(attributes = nil, *args)
    super attributes
    self.filters ||= {}
    @options ||= {}    
    self.include_subprojects = false
  end

  def initialize_available_filters
    add_available_filter 'assigned_to_id', type: :list_optional, values: assigned_to_values
    add_available_filter 'project_id', type: :list_optional, values: all_projects_values unless project
    add_available_filter 'work_package_id', type: :integer
  end

  def assigned_to_values
    assigned_to_values = []
    assigned_to_values << ["<< #{l(:label_me)} >>", 'me'] if User.current.logged?
    assigned_to_values += users.sort_by(&:status).collect { |s| [s.name, s.id.to_s] }
    assigned_to_values
  end

  def show_issues
    options[:show_issues] == '1'
  end

  def show_hours
    options[:show_hours] == '1'
  end

  def show_percent
    options[:show_percent] == '1'
  end

  def show_issues=(arg)
    options[:show_issues] = (arg == '1' ? '1' : nil)
  end

  def show_project_names
    options[:show_project_names] == '1'
  end

  def show_project_names=(arg)
    options[:show_project_names] = (arg == '1' ? '1' : nil)
  end

  def show_spent_time
    options[:show_spent_time] == '1'
  end

  def show_spent_time=(arg)
    options[:show_spent_time] = (arg == '1' ? '1' : nil)
  end

  def line_title_type
    options[:line_title_type]
  end

  def line_title_type=(arg)
    # if line_title_types.include?(arg)
      options[:line_title_type] = arg
    # else
    #   raise ArgumentError.new("value must be one of: #{line_title_types.join(', ')}")
    # end
  end

  def chart_type
    options[:chart_type]
  end

  def date_from
    options[:date_from].to_date
  end

  def date_from=(arg)
    options[:date_from] = arg.to_s
  end

  def workload_type
    options[:workload_type]
  end

  def workload_type=(arg)
    options[:workload_type] = arg.to_s
  end

  def hours_workload?
    workload_type == HOURS
  end

  def build_from_params(params)
    # super
    self.show_issues = params[:show_issues] || (params[:query] && params[:query][:show_issues]) || '1'
    self.line_title_type = params[:line_title_type] || (params[:query] && params[:query][:line_title_type]) || default_line_title_type
    self.workload_type = params[:workload_type] || (params[:query] && params[:query][:workload_type]) || HOURS
    self.date_from = params[:date_from].presence || (params[:query] && params[:query][:date_from].presence) || RedmineResources.beginning_of_week
    self
  end

  private

  def available_issues(from, to)
    scope =
      WorkPackage.visible(User.current, project: project).open
        .joins(:assigned_to)
        .where(due_date: from..to.next_day(7))
        .where("#  WorkPackage.table_name}.done_ratio < 100")
    scope = scope.where(project_id: EnabledModule.where(name: 'resources').pluck(:project_id))

    %w(assigned_to_id project_id).each do |field|
      scope = scope.where(sql_by_filter(field,  WorkPackage.table_name, field)) if has_filter?(field)
    end

    scope = scope.where(sql_by_filter('work_package_id',  WorkPackage.table_name, 'id')) if has_filter?('issue_id')
    scope
  end

  def sql_by_filter(field, db_table, db_field)
    values = values_for(field).clone

    # "me" value substitution
    if field == 'assigned_to_id' && values.delete('me')
      values.push(User.current.logged? ? User.current.id.to_s : '0')
    end

    sql_for_field(field, operator_for(field), values, db_table, db_field)
  end

  def line_title_types
    RedmineResources::Charts::AllocationChart::LINE_TITLE_TYPES
  end

  def default_line_title_type
    RedmineResources::Charts::AllocationChart::TOTAL_HOURS
  end
end
