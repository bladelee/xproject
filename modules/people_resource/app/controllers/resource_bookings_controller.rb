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

class ResourceBookingsController < ApplicationController
  menu_item :resources

  # before_action :require_login, :find_project_by_project_id, :find_user_by_user_id, only: :issues_autocomplete
  before_action :require_login, only: [:create, :update, :destroy]
  before_action :find_optional_project
  before_action :find_resource_booking, only: [:destroy, :split, :show]
  # before_action :build_resource_booking_from_params, only: [:new, :create, :edit, :update]
  # before_action :collect_work_data, only: [:new, :edit]
  # before_action :set_user_blocks_to_update, only: [:new, :create, :update, :destroy, :split]

  # accept_api_auth :index, :show, :create, :update, :destroy

  # helper :issues
  helper :queries
  include ResourceBookingsHelper
  include QueriesHelper
  include Redmine::Utils::DateCalculation

  helper_method :current_employee

  # def index
  #   retrieve_query

  #   # if @query.valid?
  #     respond_to do |format|
  #       format.html do
  #         @rb_chart = @query.chart_class.new(@project, @query, params)
  #       end
  #       format.api do
  #         # if User.current.allowed_to?(:view_resources, nil, :global => true)  view_work_packages
  #         # if User.current.allowed_to?(:view_work_packages, nil, :global => true)        
  #           @resources = ResourceBooking.visible
  #           @resource_count = @resources.count
  #         # end
  #       end
  #     end
  #   # else
  #   #   puts "@query is invalid. Errors:"
  #   #   @query.errors.full_messages.each do |msg|
  #   #     puts msg
  #   #   end
  #   # end
  # end

# def index
#   retrieve_query

#   if @query.valid?
#     respond_to do |format|
#       format.html do
#         @rb_chart = @query.chart_class.new(@project, @query, params)
#       end
#       # format.api do
#       #   # if User.current.allowed_to?(:view_resources, nil, :global => true)  view_work_packages
#       #   # if User.current.allowed_to?(:view_work_packages, nil, :global => true)        
#       #     @resources = ResourceBooking.visible
#       #     @resource_count = @resources.count
#       #   # end
#       # end
#       format.json do
#         Rails.logger.info "----------------@resources = ResourceBooking.visible"
#         @resources = ResourceBooking.visible
#         render json: { resources: @resources, resource_count: @resource_count }
#       end
#     end
#   else
#     puts "@query is invalid. Errors:"
#     @query.errors.full_messages.each do |msg|
#       puts msg
#     end
#   end
# end

# format.json do
#   @resources = ResourceBooking.visible
#   json_response = {
#     resources: @resources.map do |resource|
#       {
#         id: resource.id,
#         name: resource.name,
#         start_date: resource.start_date,
#         end_date: resource.end_date
#       }
#     end,
#     resource_count: @resources.count
#   }
#   render json: json_response
# end


  def index
    respond_to do |format|
      format.html do
        set_chart_display_default_params
        filter_users 
        retrieve_query      
        @rb_chart = @query.chart_class.new(@project, @query, params)
        render layout: "global"
      end
      format.json do
        retrieve_query         
        if @query.valid?
            Rails.logger.info "----------------@resources = ResourceBooking.visible"        
            # @resources = ResourceBooking.visible
            # @resource_count = @resources.count
            # render json: { resources: @resources, resource_count: @resource_count }
            index_json
        else
          puts "@query is invalid. Errors:"
          @query.errors.full_messages.each do |msg|
            puts msg
          end
          render json: { errors: @query.errors.full_messages }, status: :unprocessable_entity
        end
      end
    end
  end 

  def set_chart_display_default_params

    puts "-----session0------------#{session}"
    puts "-----params0------------#{params}"  

    default_params = {
      chart_type: 'utilization_report',
      group_by: 'issue',
      show_spent_time: 0,
      show_percent: 0,
      show_hours: 1,
    }
    session[:filter_params] = default_params
    params.merge!(default_params) 

    puts "-----session1------------#{session}"
    puts "-----params1------------#{params}"  
  end


  def filter_users
    @departments = Department.all
    @projects = Project.all
    
    # 如果没有任何筛选参数，设置默认值
    #    if !params[:commit] && !session[:filter_params]
    # 设置默认筛选参数
    if !session[:department_ids]  
      session[:department_ids] = Department.where(parent_id: nil).pluck(:id)   # 默认选择所有根部门
    end
    if !session[:project_ids]  
      session[:project_ids] = Project.pluck(:id)  # 默认选择所有项目
    end
    if !session[:start_date] ||  !session[:start_date].is_a?(Date)
      # session[:start_date] = Date.current  # 默认起始时间为当前日期
      session[:start_date] = '2025-02-22'
      params[:start_date] = session[:start_date]
      puts "-----set start date------------#{session[:start_date]}"
    end
    # puts "-----session[:start_date]------------#{session[:start_date]}-------#{session[:start_date].class}"
    # session[:filter_params][:date_from] = session[:start_date].to_s

    puts "-----session2------------#{session[:filter_params]}"
    puts "-----params2------------#{params}"

    #    end
    
    # 保存筛选条件到会话
    session[:filter_params] = filter_params if params[:commit].present?
    # 清除筛选
    session[:filter_params] = nil if params[:reset].present?
    
    @employees = filter_employees(session[:filter_params])
  end


  def index_json
    user_ids = params[:user_ids]&.split(',')
    from_date = params[:date_from]&.to_date
    to_date = params[:date_to]&.to_date

    # 验证日期范围的有效性
    if from_date && to_date && from_date > to_date
      return render json: { error: 'from_date cannot be after to_date' }, status: :unprocessable_entity
    end

    # 构建查询
    bookings = ResourceBooking.includes(:work_package)
    bookings = bookings.where(assigned_to_id: user_ids) if user_ids.present?
    if from_date && to_date
      bookings = bookings.where('start_date <=? AND (end_date >=? OR end_date IS NULL)', to_date, from_date)
    elsif from_date
      bookings = bookings.where('start_date >=?', from_date)
    elsif to_date
      bookings = bookings.where('start_date <=? AND (end_date >=? OR end_date IS NULL)', to_date, to_date)
    end
    puts "----------------bookings sql? = #{bookings.to_sql}"

    # 处理 bookings 为空的情况
    if bookings.empty?
      result = user_ids.map do |user_id|
        {
          user_id: user_id.to_i,
          id_mappings: [],
          work_loads: {}
        }
      end
      return render json: result
    end

    # 按用户分组处理数据
    user_bookings = bookings.group_by(&:assigned_to_id)
    result = user_bookings.map do |assigned_to_id, user_booking_list|
      work_loads = {}
      id_mappings = []
      user_booking_list.each do |booking|
        current_date = [booking.start_date.to_date, from_date].max
        end_date = [booking.end_date&.to_date || current_date, to_date].min

        # 添加 id_mapping
        puts "------------------------------booking.hours: #{booking.hours.inspect}"
        id_mappings << {
          work_package_id: booking.work_package&.id,
          resource_booking_id: booking.id,
          hours_per_day: booking.hours_per_day,
          hours: booking.hours
        }

        while current_date <= end_date
          date_str = current_date.strftime('%Y-%m-%d')
          work_loads[date_str] ||= { planned_h_total: 0, work_packages: {} }
          work_loads[date_str][:planned_h_total] += calculate_planned_hours(booking, current_date)
          work_package_id = booking.work_package&.id.to_s
          work_loads[date_str][:work_packages][work_package_id] ||= { planned_h: 0 }
          work_loads[date_str][:work_packages][work_package_id][:planned_h] += calculate_planned_hours(booking, current_date)
          current_date += 1.day
        end
      end

      {
        user_id: assigned_to_id,
        id_mappings: id_mappings,
        work_loads: work_loads
      }
    end

    render json: result
  end

  def calculate_planned_hours(booking, current_date)
    if booking.hours_per_day.present? && booking.hours_per_day != 0
      booking.hours_per_day
    else
      days_since_start = (current_date - booking.start_date.to_date).to_i
      booking.hours[days_since_start] || 0
    end
  end


  # 创建一个新的资源预订记录
  def create
    booking = ResourceBooking.new(booking_params)
    if booking.save
      render json: booking, status: :created
    else
      render json: booking.errors, status: :unprocessable_entity
    end
  end

  # 显示单个资源预订记录
  def show
    booking = ResourceBooking.find_by(id: params[:id])
    if booking
      render json: booking
    else
      render json: { error: 'Resource booking not found' }, status: :not_found
    end
  end

  # 更新一个现有的资源预订记录
  def update
    booking = ResourceBooking.find_by(id: params[:id])
    if booking
      if booking.update(booking_params)
        render json: booking
      else
        render json: booking.errors, status: :unprocessable_entity
      end
    else
      render json: { error: 'Resource booking not found' }, status: :not_found
    end
  end

  def booking_params
    params.require(:resource_booking).permit(
      :project_id,
      :assigned_to_id,
      :work_package_id,
      :author_id,
      :start_date,
      :end_date,
      :hours_per_day,
      :notes,
      hours: []
    )
  end

  


  def new
  end

  # def create
  #   if @resource_booking.save
  #     respond_to do |format|
  #       format.js do
  #         add_to_flash_resource_booking_warnings
  #         render_update_chart l(:notice_successful_create)
  #       end
  #       format.api do
  #         render :action => 'show', :status => :created
  #       end
  #     end
  #   else
  #     respond_to do |format|
  #       format.js do
  #         render :new
  #       end
  #       format.api do
  #         render_validation_errors(@resource_booking)
  #       end
  #     end
  #   end
  # end

  # def show
  #   respond_to do |format|
  #     format.api do
  #       @resource_booking
  #     end
  #   end
  # end

  def edit
    # Run validations (There is no method "validate" in Rails 3)
    @resource_booking.valid?
  end

  # def update
  #   if @resource_booking.save
  #     respond_to do |format|
  #       format.js do
  #         add_to_flash_resource_booking_warnings
  #         render_update_chart l(:notice_successful_update)
  #       end
  #       format.api do
  #         render_api_ok
  #       end
  #     end
  #   else
  #     respond_to do |format|
  #       format.js do
  #         collect_work_data
  #         render :edit
  #       end
  #       format.api do
  #         render_validation_errors(@resource_booking)
  #       end
  #     end
  #   end
  # end

  def destroy
    if @resource_booking.destroy
      respond_to do |format|
        format.js do
          render_update_chart l(:notice_successful_delete)
        end
        format.api do
          render_api_ok
        end
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:error] = l(:notice_could_not_delete)
          render partial: 'update_chart'
        end
        format.api do
          render_api_ok
        end
      end
    end
  end

  def split
    split_date = @resource_booking.start_date + params[:split_offset].to_i.days
    new_resource_booking = @resource_booking.dup
    @resource_booking.end_date = split_date - 1.day
    new_resource_booking.start_date = split_date

    ResourceBooking.transaction do
      if @resource_booking.save && new_resource_booking.save
        render_update_chart l(:notice_successful_create)
      else
        flash.now[:error] = l(:error_save_failed)
        render partial: 'update_chart'
        raise ActiveRecord::Rollback
      end
    end
  end

  # def issues_autocomplete
  #   @issues = []
  #   q = (params[:q] || params[:term]).to_s.strip
  #   scope = Issue
  #   scope = scope.includes(:tracker).where(project_id: @project.id) if @project.present?

  #   if q.present?
  #     if q.match(/\A#?(\d+)\z/)
  #       @issues << scope.find_by_id($1.to_i)
  #     end
  #   end

  #   scope = scope.like(q).select_with_sorting_by_groups(@user.id)
  #   @issues += scope.limit(Issue::SELECT2_ISSUES_LIMIT).to_a
  #   @issues.compact!

  #   render json: Issue.build_issues_select2_data(@issues, @user)
  # end

  private

  def add_to_flash_resource_booking_warnings
    if @resource_booking.warnings.present?
      flash.now[:warning] = @resource_booking.warnings.full_messages.join('; ')
    end
  end

  def render_update_chart(notice)
    if @user_blocks
      flash.now[:notice] = notice
      render partial: 'update_chart', locals: { resize: true }
    else
      flash[:notice] = notice
      render js: "window.location = '#{bookings_index_path}'"
    end
  end

  def set_user_blocks_to_update
    retrieve_query
    @query.add_filter('assigned_to_id', '=', [@resource_booking.assigned_to_id.to_s])
    return unless @query.valid?

    @user_blocks = { @resource_booking.assigned_to_id => RedmineResources::Charts::AllocationChart.new(@project, @query) }

    assigned_to_id_was = @resource_booking.assigned_to_id_was
    if assigned_to_id_was && (@resource_booking.assigned_to_id != assigned_to_id_was)
      query = @query.dup
      query.add_filter('assigned_to_id', '=', [assigned_to_id_was.to_s])
      @user_blocks[assigned_to_id_was] = RedmineResources::Charts::AllocationChart.new(@project, query)
    end
  end

  def find_resource_booking
    @resource_booking = ResourceBooking.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def build_resource_booking_from_params
    if params[:id].blank?
      @resource_booking = ResourceBooking.new(project: @project, author: User.current)
    else
      return unless find_resource_booking
    end

    @resource_booking.safe_attributes = params[:resource_booking]

    if params[:zoom] && params[:zoom].to_i == 1 # monthly scale
      @resource_booking.start_date += params[:start_date_offset].to_i.months if params[:start_date_offset]
      @resource_booking.end_date = @resource_booking.get_end_date + params[:end_date_offset].to_i.months if params[:end_date_offset]
      @resource_booking.end_date = @resource_booking.end_date.end_of_month if @resource_booking.new_record?
    elsif params[:zoom] && params[:zoom].to_i == 2 # weekly scale
      @resource_booking.start_date += params[:start_date_offset].to_i.weeks if params[:start_date_offset]
      @resource_booking.end_date = @resource_booking.get_end_date + params[:end_date_offset].to_i.weeks if params[:end_date_offset]
      @resource_booking.end_date = @resource_booking.end_date.end_of_week if @resource_booking.new_record?
    else # daily scale
      @resource_booking.start_date += params[:start_date_offset].to_i.days if params[:start_date_offset]
      @resource_booking.end_date = @resource_booking.get_end_date + params[:end_date_offset].to_i.days if params[:end_date_offset]
    end
  end

def retrieve_query
  session_key = :resource_booking_query
  if params[:set_filter] || session[session_key].nil? || session[session_key][:project_id] != (@project ? @project.id : nil)
    Rails.logger.debug "Creating new query because: set_filter=#{params[:set_filter]}, session[session_key].nil?=#{session[session_key].nil?}, project_id mismatch=#{session[session_key] && session[session_key][:project_id] != (@project ? @project.id : nil)}"
    # Give it a name, required to be valid
    @query = ResourceBookingQuery.new(name: '_', project: @project)
    # @query.build_from_params(params)
    # 修改后的查询构建部分
    @query.build_from_params(params)
    # unless @query.filters.any? { |f| f[:name].to_s == 'include_subprojects' }
    #   puts "Adding include_subprojects filter"
    #   @query.add_filter('include_subprojects', '=', ['false'])
    # end
    session[session_key] = { project_id: @query.project_id, group_by: @query.group_by, filters: @query.filters, options: @query.options }
    Rails.logger.debug "Params: #{params}"
    puts "project_id: #{@query.project_id}"
    puts "group_by: #{@query.group_by}"
    puts "filters: #{@query.filters}"
    puts "options: #{@query.options}"    
  else
    Rails.logger.debug "Retrieving query from session"
    # retrieve from session
  #  puts "-----params[:date_from]------------#{params[:date_from]}}"
  #  session[session_key][:options][:date_from] = params[:date_from].to_date if params[:date_from]

    puts "-----params[:date_from]------------#{params[:start_date]}}"
    session[session_key][:options][:date_from] = params[:start_date].to_date if params[:start_date]
    # session[session_key][:options][:date_from] = "#{params[:year]}-#{params[:month]}-01".to_date if (params[:year] && params[:month])
    @query = ResourceBookingQuery.new(name: '_', group_by: session[session_key][:group_by], filters: session[session_key][:filters], options: session[session_key][:options])
    @query.project = @project
    # @query.build_from_params(params)
  end
  @query
end


  # Retrieve query from session or build a new query
  # def retrieve_query
  #   session_key = :resource_booking_query
  #   if params[:set_filter] || session[session_key].nil? || session[session_key][:project_id] != (@project ? @project.id : nil)
  #     # Give it a name, required to be valid
  #     @query = ResourceBookingQuery.new(name: '_', project: @project)
  #     @query.build_from_params(params)
  #     session[session_key] = { project_id: @query.project_id, group_by: @query.group_by, filters: @query.filters, options: @query.options }
  #   else
  #     # retrieve from session
  #     session[session_key][:options][:date_from] = params[:date_from].to_date if params[:date_from]
  #     session[session_key][:options][:date_from] = "#{params[:year]}-#{params[:month]}-01".to_date if (params[:year] && params[:month])
  #     @query = ResourceBookingQuery.new(name: '_', group_by: session[session_key][:group_by], filters: session[session_key][:filters], options: session[session_key][:options])
  #     @query.project = @project
  #   end
  #   @query
  # end

  def find_user_by_user_id
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def collect_work_data
    @issue = @resource_booking.issue
    @projects = ResourceBooking.allowed_projects
    @resource_booking_project = @resource_booking.project || @projects.first

    users = @resource_booking_project.users
    selected_user = users.find_by(id: @resource_booking.assigned_to_id) || users.first
    @person = RedmineResources.people_pro_plugin_installed? && selected_user && selected_user.becomes(Person)

    @user_workday_length = @person.try(:workday_length) || RedmineResources.default_workday_length
    @resource_booking.assigned_to = selected_user
  end

  def filter_params
    params.permit(:start_date, department_ids: [], project_ids: [])
  end

  def filter_employees(filters)
    # 基于用户角色的基础查询
    employees = base_employee_scope
    return employees unless filters.present?

    # 应用部门筛选
    if filters[:department_ids].present?
      department_ids = Array(filters[:department_ids]).reject(&:blank?)
      if department_ids.any?
        if current_employee.department_manager?
          # 部门经理只能看到自己部门的员工，如果筛选其他部门则返回空
          if (department_ids & [current_employee.department_id]).empty?
            return Employee.none
          end
          department_ids = [current_employee.department_id]
        end
        
        all_department_ids = []
        Department.where(id: department_ids).each do |dept|
          all_department_ids += [dept.id] + dept.descendants.pluck(:id)
        end
        employees = employees.where(department_id: all_department_ids.uniq)
      end
    end

    # 应用项目筛选
    if filters[:project_ids].present?
      project_ids = Array(filters[:project_ids]).reject(&:blank?)
      if project_ids.any?
        if current_employee.project_manager?
          # 项目经理只能看到自己管理的项目中的员工，如果筛选其他项目则返回空
          managed_project_ids = current_employee.managed_projects.pluck(:id)
          if (project_ids & managed_project_ids).empty?
            return Employee.none
          end
          project_ids = managed_project_ids
        end
        
        employees = employees.joins(:members)
                           .where(members: { project_id: project_ids })
                           .distinct
      end
    end

    employees
  end

  def base_employee_scope
    if current_employee.admin?
      Employee.all
    elsif current_employee.department_manager?
      Employee.where(department_id: current_employee.department_id)
    elsif current_employee.project_manager?
      project_ids = current_employee.managed_projects.pluck(:id)
      Employee.joins(:members).where(members: { project_id: project_ids }).distinct
    else
      Employee.where(id: current_employee.id)
    end
  end

  def current_employee
    # 使用 ||= 实现缓存，避免重复查询
    @current_employee ||= current_user.becomes(Person)
  end

  
    

end
