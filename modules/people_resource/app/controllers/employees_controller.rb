class EmployeesController < ApplicationController

  layout 'employees_layout'

  def index
    @departments = Department.all
    @projects = Project.all
    
    # 保存筛选条件到会话
    session[:filter_params] = filter_params if params[:commit].present?
    # 清除筛选
    session[:filter_params] = nil if params[:reset].present?
    
    @employees = filter_employees(session[:filter_params])
  end

  private

  def filter_params
    params.permit(:name, :position, department_ids: [], project_ids: [])
  end

  def filter_employees(filters)
    employees = Employee.all

    if filters.present?
      # 部门筛选
      if filters[:department_ids].present?
        department_ids = filters[:department_ids].reject(&:blank?)
        if department_ids.any?
          all_department_ids = []
          Department.find(department_ids).each do |dept|
            # 包含选中的部门及其所有子部门
            all_department_ids += [dept.id] + dept.descendants.pluck(:id)
          end
          employees = employees.where(department_id: all_department_ids.uniq)
        end
      end

      # 项目筛选
      if filters[:project_ids].present?
        project_ids = filters[:project_ids].reject(&:blank?)
        if project_ids.any?
          employees = employees.joins(:employee_projects)
                              .where(employee_projects: { project_id: project_ids })
                              .distinct
        end
      end

      # 姓名筛选
      if filters[:name].present?
        employees = employees.where("name LIKE ?", "%#{filters[:name]}%")
      end

      # 职位筛选
      if filters[:position].present?
        employees = employees.where("position LIKE ?", "%#{filters[:position]}%")
      end
    end

    employees
  end
end 
