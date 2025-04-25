require 'rails_helper'

RSpec.describe EmployeesController, type: :controller do
  describe '#filter_employees' do
    # let!(:company) { create(:company) }
    # let!(:dept_a) { create(:department, company: company) }
    # let!(:dept_b) { create(:department, company: company) }
    let!(:dept_a) { create(:department) }
    let!(:dept_b) { create(:department) }    
    let!(:project_1) { create(:project) }
    let!(:project_2) { create(:project) }
    
    # 创建不同角色的用户
    let!(:admin) { create(:employee, role: 'admin', department: dept_a) }
    let!(:dept_manager) { create(:employee, role: 'department_manager', department: dept_a) }
    let!(:project_manager) { create(:employee, role: 'project_manager', department: dept_a, projects: [project_1]) }
    let!(:regular_employee) { create(:employee, role: 'employee', department: dept_a, projects: [project_1]) }
    
    # 创建测试数据
    let!(:emp_in_dept_a) { create(:employee, department: dept_a, projects: [project_1]) }
    let!(:emp_in_dept_b) { create(:employee, department: dept_b, projects: [project_2]) }
    let!(:emp_in_project_1) { create(:employee, department: dept_b, projects: [project_1]) }

    context '当用户是管理层时' do
      before { sign_in admin }

      it '能看到所有员工' do
        get :index
        expect(assigns(:employees)).to include(emp_in_dept_a, emp_in_dept_b, emp_in_project_1)
      end

      it '能按部门筛选' do
        get :index, params: { department_ids: [dept_a.id] }
        expect(assigns(:employees)).to include(emp_in_dept_a)
        expect(assigns(:employees)).not_to include(emp_in_dept_b)
      end
    end

    context '当用户是部门经理时' do
      before { sign_in dept_manager }

      it '只能看到本部门的员工' do
        get :index
        expect(assigns(:employees)).to include(emp_in_dept_a)
        expect(assigns(:employees)).not_to include(emp_in_dept_b)
      end

      it '筛选其他部门时看不到数据' do
        get :index, params: { department_ids: [dept_b.id] }
        expect(assigns(:employees)).to be_empty
      end
    end

    context '当用户是项目经理时' do
      before { sign_in project_manager }

      it '只能看到自己管理项目中的员工' do
        get :index
        expect(assigns(:employees)).to include(emp_in_dept_a, emp_in_project_1)
        expect(assigns(:employees)).not_to include(emp_in_dept_b)
      end

      it '筛选其他项目时看不到数据' do
        get :index, params: { project_ids: [project_2.id] }
        expect(assigns(:employees)).to be_empty
      end
    end

    context '当用户是普通员工时' do
      before { sign_in regular_employee }

      it '只能看到自己的信息' do
        get :index
        expect(assigns(:employees)).to contain_exactly(regular_employee)
      end

      it '使用任何筛选条件都只能看到自己' do
        get :index, params: { department_ids: [dept_a.id], project_ids: [project_1.id] }
        expect(assigns(:employees)).to contain_exactly(regular_employee)
      end
    end
  end
end