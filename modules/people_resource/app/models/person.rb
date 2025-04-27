# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2024 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

require_relative "../../lib/redmine/safe_attributes.rb"

class Person < User

  include Redmine::SafeAttributes
  #include Redmine::Pagination
  # attr_accessor :auth_source_id,:custom_field_values,:custom_fields, :status, :mail_notification,:notified_project_ids
  # attr_accessor :admin,:custom_field_values,:custom_fields, :status, :login, :notified_project_ids, :mail_notification, :auth_source_id, :information_attributes,
  #              :is_system, :middlename, :gender,:birthday,:address,:phone,:job_title,:department_id,:manager_id,:appearance_date,:background

  self.inheritance_column = :_type_disabled

  # before_save :ensure_information

  has_one :information, :class_name => 'PeopleInformation', :foreign_key => :user_id, :dependent => :destroy
  belongs_to :station

  delegate :phone, :address, :skype, :birthday, :job_title, :company, :middlename, :gender, :twitter,
           :facebook, :linkedin, :department_id, :background, :appearance_date, :is_system, :manager_id,
           :to => :information, :allow_nil => true

  acts_as_customizable

  accepts_nested_attributes_for :information, :allow_destroy => true, :update_only => true, :reject_if => proc { |attributes| PeopleInformation.reject_information(attributes) }

  has_one :department, :through => :information

  has_one :manager, :through => :information

  has_many :time_entries, foreign_key: :user_id, dependent: :destroy

  #up_acts_as_taggable

  scope :in_department, lambda { |department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    eager_load(:information).where("(#{PeopleInformation.table_name}.department_id = ?) AND (#{Person.table_name}.type = 'User')", department_id)
  }
  scope :not_in_department, lambda { |department|
    department_id = department.is_a?(Department) ? department.id : department.to_i
    eager_load(:information).where("(#{PeopleInformation.table_name}.department_id != ?) OR (#{PeopleInformation.table_name}.department_id IS NULL)", department_id)
  }

  scope :seach_by_name, lambda { |search| eager_load([:information, :email_address])
                                          .where("(LOWER(#{Person.table_name}.firstname) LIKE :search OR
                                                   LOWER(#{Person.table_name}.lastname) LIKE :search OR
                                                   LOWER(#{PeopleInformation.table_name}.middlename) LIKE :search OR
                                                   #{concated_names_sql}
                                                   LOWER(#{Person.table_name}.login) LIKE :search OR
                                                   LOWER(#{EmailAddress.table_name + '.address'}) LIKE :search)",
                                                   :search => search.downcase + '%') }

  scope :managers, lambda { joins("INNER JOIN #{PeopleInformation.table_name} ON #{Person.table_name}.id = #{PeopleInformation.table_name}.manager_id").uniq }



  safe_attributes 'custom_field_values',
                  'custom_fields',
                  'information_attributes',
                  'auth_source_id',
                  'station_id'
    # :if => lambda { |person, user| (person.new_record? && user.allowed_people_to?(:add_people, person)) || user.allowed_people_to?(:edit_people, person) }

  # safe_attributes 'status'
    # :if => lambda { |person, user| user.allowed_people_to?(:edit_people, person) && person.id != user.id && !person.admin }

  safe_attributes 'tag_list'
    # :if => lambda { |person, user| user.allowed_people_to?(:manage_tags, person) }


  def self.genders
    [['男', 0], ['女', 1]]
  end

  def type
    'User'
  end

  def email
    mail
  end

  def project
    nil
  end

  def subordinates
    scope = Person.eager_load(:information).where("#{PeopleInformation.table_name}.manager_id" => id.to_i)
    scope = scope.visible if Person.respond_to?(:visible)
    scope
  end

  def available_managers
    scope = Person.eager_load(:information).where("#{Person.table_name}.type" => 'User')
    scope = scope.visible if Person.respond_to?(:visible)

    if id.present?
      scope = scope.where("#{PeopleInformation.table_name}.manager_id != ? OR #{PeopleInformation.table_name}.manager_id IS NULL", id.to_i)
                   .where("#{Person.table_name}.id <> ?", id.to_i)
    end
    scope
  end

  def available_subordinates
    scope = Person.eager_load(:information).where("#{Person.table_name}.type" => 'User')
    scope = scope.visible if Person.respond_to?(:visible)

    if id.present?
      scope = scope.where("#{PeopleInformation.table_name}.manager_id != ? OR #{PeopleInformation.table_name}.manager_id IS NULL", id.to_i)
                   .where("#{Person.table_name}.id <> ?", id.to_i)
      scope = scope.where("#{Person.table_name}.id != ?", manager_id.to_i) if manager_id.present?
    end
    scope
  end

  def phones
    @phones || phone ? phone.split(/, */) : []
  end

  def next_birthday
    return if birthday.blank?
    year = Date.today.year
    mmdd = birthday.strftime('%m%d')
    year += 1 if mmdd < Date.today.strftime('%m%d')
    mmdd = '0301' if mmdd == '0229' && !Date.parse("#{year}0101").leap?
    Date.parse("#{year}#{mmdd}")
  end

  def age
    return nil if birthday.blank?
    now = Time.now
    now.year - birthday.year - (birthday.to_time.change(:year => now.year) > now ? 1 : 0)
  end

  def editable_by?(_usr, _prj = nil)
    true
    # usr && (usr.allowed_to?(:edit_people, prj) || (self.author == usr && usr.allowed_to?(:edit_own_invoices, prj)))
    # usr && usr.logged? && (usr.allowed_to?(:edit_notes, project) || (self.author == usr && usr.allowed_to?(:edit_own_notes, project)))
  end

  def visible?(user = User.current)
    principal = Principal.visible(user).where(:id => id).first
    return principal.present?
  end

  def attachments_visible?(_user = User.current)
    true
  end

  def available_custom_fields
    CustomField.where("type = 'UserCustomField'").sort.to_a
  end

  def remove_subordinate(subordinate_id)
    subordinate = Person.find(subordinate_id.to_i)
    return false if subordinate.blank?

    #subordinate.safe_attributes = { 'information_attributes' => { 'manager_id' => nil } }
    subordinate.save
  end

  def all_visible_attachments
    attachments.select { |a| a != avatar } if visible?
  end

  def all_visible_memberships
    memberships.where(Project.visible_condition(User.current)) if visible?
  end

  def all_visible_events
    Redmine::Activity::CrmFetcher.new(User.current, :author => self).events(nil, nil, :limit => 10).group_by(&:event_date) if visible?
  end

  def all_visible_subordinates(page, limit)
    if visible?
      subordinates_count = subordinates.count
      subordinate_pages = Paginator.new(subordinates_count, limit, page)
      offset = subordinate_pages.offset
      subordinates.limit(limit).offset(offset)
    end
  end

  attr_reader :global_role

  def initialize(*)
    super
    @global_role = nil
  end

  # def ensure_information
  #   puts 'ensure_information-----------------------, information = ', information
  #   build_information unless information
  # end


  # 定义角色枚举
  module Roles
    ADMIN = 'admin'
    DEPARTMENT_MANAGER = 'department_manager'
    PROJECT_MANAGER = 'project_manager'
    EMPLOYEE = 'employee'

    ALL = [ADMIN, DEPARTMENT_MANAGER, PROJECT_MANAGER, EMPLOYEE].freeze

    def self.options_for_select
      [
        ['管理员', ADMIN],
        ['部门经理', DEPARTMENT_MANAGER],
        ['项目经理', PROJECT_MANAGER],
        ['普通员工', EMPLOYEE]
      ]
    end
  end

  # 修改 global_role 方法使用新的枚举
  def global_role
    return @global_role if @global_role.present?
    
    roles = Authorization::UserGlobalRolesQuery.query(User.current)

    if roles.any? == false
      @global_role = Roles::EMPLOYEE
    elsif roles.any? { |r| r.has_permission?(:view_all_employees) }
      @global_role = Roles::ADMIN
    elsif roles.any? { |r| r.has_permission?(:manage_department_employees) }
      @global_role = Roles::DEPARTMENT_MANAGER
    elsif roles.any? { |r| r.has_permission?(:manage_project_employees) }
      @global_role = Roles::PROJECT_MANAGER
    else
      @global_role = Roles::EMPLOYEE
    end
    
    @global_role
  end

  # 修改角色判断方法使用新的枚举
  def admin?
    global_role == Roles::ADMIN
  end

  def department_manager?
    global_role == Roles::DEPARTMENT_MANAGER
  end

  def project_manager?
    global_role == Roles::PROJECT_MANAGER
  end

  def employee?
    global_role == Roles::EMPLOYEE
  end

  # 修改 managed_projects 方法使用新的枚举
  def managed_projects
    return Project.all if admin?
    members.active.joins(:roles)
          .where(roles: { code: Roles::PROJECT_MANAGER })
          .map(&:project)
  end

  # 添加一些辅助方法
  def role_name
    case global_role
    when Roles::ADMIN
      '管理员'
    when Roles::DEPARTMENT_MANAGER
      '部门经理'
    when Roles::PROJECT_MANAGER
      '项目经理'
    else
      '普通员工'
    end
  end

  # 类方法
  class << self
    def emails
      joins(:email_address).pluck("LOWER(#{EmailAddress.table_name}.address)")
    end

    def next_birthdays(limit = 10)
      Person.eager_load(:information).active.where("#{PeopleInformation.table_name}.birthday IS NOT NULL").sort_by(&:next_birthday).first(limit)
    end

    def tomorrow_birthdays
      Person.next_birthdays.select { |p| p.next_birthday == Date.today + 1 }
    end

    def today_birthdays
      Person.next_birthdays.select { |p| p.next_birthday == Date.today }
    end

    def week_birthdays
      Person.next_birthdays.select { |p| p.next_birthday <= Date.today.end_of_week && p.next_birthday > Date.tomorrow }
    end

    def all_visible
      scope = Person.active
      scope = scope.visible
      scope
    end

    def all_visible_next_birthdays
      next_birthdays = Person.all_visible
      next_birthdays.next_birthdays
    end

    def all_visible_new_people
      new_people = Person.all_visible
      new_people.eager_load(:information)
                .where("#{PeopleInformation.table_name}.appearance_date IS NOT NULL")
                .where("#{PeopleInformation.table_name}.appearance_date > ?", Date.today - 30.days)
                .order("#{PeopleInformation.table_name}.appearance_date desc")
                .first(5)
    end

    def concated_names_sql
      case ActiveRecord::Base.connection.class.name
      when /Mysql/
        return 'LOWER(CONCAT(firstname, lastname)) LIKE :search OR LOWER(CONCAT(lastname, firstname)) LIKE :search OR'
      when /SQLServer/
        return 'LOWER(firstname + lastname) LIKE :search OR LOWER(lastname + firstname) LIKE :search OR'
      end
      'LOWER(firstname || lastname) LIKE :search OR LOWER(lastname || firstname) LIKE :search OR'
    end

    def roles_for_select
      Roles.options_for_select
    end

    def valid_role?(role)
      Roles::ALL.include?(role)
    end
  end
end
