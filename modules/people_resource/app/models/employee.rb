class Employee < ApplicationRecord
  belongs_to :department
  has_many :members, dependent: :destroy
  has_many :projects, through: :members
  has_many :member_roles, through: :members
  has_many :roles, through: :member_roles
  
  validates :name, presence: true
  
  attr_reader :global_role
  
  def initialize(*)
    super
    @global_role = nil
  end
  
  def global_role
    return @global_role if @global_role.present?
    
    if roles.any? == false
      @global_role = Role::EMPLOYEE
    elsif roles.any? { |r| r.has_permission?(:view_all_employees) }
      @global_role = Role::ADMIN
    elsif roles.any? { |r| r.has_permission?(:manage_department_employees) }
      @global_role = Role::DEPARTMENT_MANAGER
    elsif roles.any? { |r| r.has_permission?(:manage_project_employees) }
      @global_role = Role::PROJECT_MANAGER
    else
      @global_role = Role::EMPLOYEE
    end
    
    @global_role
  end
  
  # def has_role?(role_code)
  #   roles.exists?(code: role_code)
  # end
  
  def admin?
    global_role == Role::ADMIN
  end
  
  def department_manager?
    global_role == Role::DEPARTMENT_MANAGER
  end
  
  def project_manager?
    global_role == Role::PROJECT_MANAGER
  end
  
  def managed_projects
    return Project.all if admin?
    members.active.joins(:roles)
          .where(roles: { code: Role::PROJECT_MANAGER })
          .map(&:project)
  end
end 