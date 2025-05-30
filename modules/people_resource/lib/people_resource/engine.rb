# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2021-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require 'redmineup'

module PeopleResource
  class Engine < ::Rails::Engine
    engine_name :people_resource

    include OpenProject::Plugins::ActsAsOpEngine

    register "people_resource",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: {} do
=begin
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.map do |ac_map|
          #ac_map.project_module(:people_resource, dependencies: :work_package_tracking, order: 95)
        end

        OpenProject::AccessControl.permission(:view_work_packages).tap do |add|
          add.controller_actions << "departments/departments/index"
          #add.controller_actions << "gantt/gantt/menu"
          #add.controller_actions << "gantt/menus/show"
        end
      end
=end

      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.map do |ac_map|
          ac_map.project_module(:people_resource, dependencies: :work_package_tracking, order: 99)
        end

        OpenProject::AccessControl.permission(:view_work_packages).tap do |add|
          add.controller_actions << "resource_bookings/index"
          add.controller_actions << "resource_bookings/create"
          add.controller_actions << "resource_bookings/show"
          add.controller_actions << "resource_bookings/update"                    
        end

        # OpenProject::AccessControl.permission(:view_resources).tap do |add|
        #   add.controller_actions << "resource_bookings/index"
        # end
      end

      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
        User.current.allowed_in_any_project?(:view_work_packages)
      end

      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
        User.current.allowed_in_any_project?(:view_work_packages)
      end

      should_render_project_menu = Proc.new do |project|
        project.module_enabled?(:department)
      end

      menu :global_menu,
           :people_resources,
           { controller: "/departments", action: "index", project_id: nil },
           caption: :label_people_resources_plural,
           after: :work_packages,
           icon: "view-timeline",
           if: should_render_global_menu_item

      menu :global_menu,
           :departments,
           { controller: "/departments", action: "index", project_id: nil },
           parent: :people_resources,
           caption: :label_department_plural,
           last: true,
           #after: :work_packages,
           icon: "view-timeline",
           if: should_render_global_menu_item

      menu :global_menu,
            :resource_bookings,
            { controller: "/resource_bookings", action: "index", project_id: nil },
            caption: :label_resources_calendar_plural,
            after: :people_resources,
            last: true,
            icon: "view-timeline",
            if: should_render_global_menu_item


      menu :global_menu,
           :peoples,
           { controller: "/people", action: "index" },
           #{ controller: "/departments/departments", action: "index", project_id: nil },
           parent: :people_resources,
           #partial: "gantt/menus/menu",
           last: true,
           icon: "view-timeline",
           caption: :label_people_person
           #if: should_render_global_menu_item


    end

    assets %w(
      arrow_right.png
    )

    if config.respond_to?(:autoloader) && config.autoloader == :zeitwerkc
      app.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/../../lib') }
      puts "people resource ----zeitwerk autoloader"
    end

    initializer "people_resource.assets.precompile" do |app|
      app.config.assets.precompile += %w( people_resource/*.js people_resource/*.css )
      app.config.assets.precompile += %w( application.js )      
      app.config.assets.precompile += %w( redmine_people.js redmine_people.css )
      app.config.assets.precompile += %w( select2.js  select2_helpers.js select2.css )
      app.config.assets.precompile += %w( jquery.glanceyear.js )
      app.config.assets.precompile += %w( redmine_resources.js redmine_resources.css )
      # app.config.assets.precompile += %w( app/javascript/controllers/*.js )
      # app.config.assets.precompile += %w( app/javascript/application2.js ) 
      # app.config.assets.paths << Engine.root.join("app/javascript")
      # 确保 JavaScript 路径被正确添加
      # app.config.javascript_path = "javascript"
      # app.config.assets.paths << root.join("app")      
      # app.config.assets.precompile += %w( javascript/application.js )

      # 添加 controllers 目录到资源路径
      app.config.assets.paths << root.join("app/javascript")
      # app.config.assets.paths << root.join("app/javascript/controllers")
      app.config.assets.precompile += %w( application2.js )
      app.config.assets.precompile += %w( controllers/application.js )
      app.config.assets.precompile += %w( controllers/index.js )
      app.config.assets.precompile += %w( controllers/department_selector_controller.js )
      app.config.assets.precompile += %w( controllers/project_selector_controller.js )           

    end

    initializer "my_plugin.importmap", before: "importmap" do |app|
      # 关键代码：将插件的 importmap.rb 路径添加到主应用的 importmap 路径列表中
      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/javascript")
    end

    # initializer "people_resource.content_security_policy" do |app|
    #   # app.config.content_security_policy = nil
    #   # app.config.content_security_policy do |policy|
    #   #   policy.script_src  :self, 
    #   #                       :https, 
    #   #                       "http://localhost:3000",
    #   #                       "ws://localhost:3000",
    #   #                       "http://localhost:4200/employees",
    #   #                       "ws://localhost:4200",
    #   #                       "https://www.ssa.gov",
    #   #                       :strict_dynamic,
    #   #                       :unsafe_inline    # 允许内联脚本  
    #   # end
    #   # app.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }
    #   # app.config.content_security_policy_nonce_directives = %w(script-src)
    #   # 完全禁用 CSP
    #   app.config.content_security_policy do |policy|
    #     policy.default_src "*"
    #     policy.script_src "*", :unsafe_inline, :unsafe_eval
    #     policy.style_src "*", :unsafe_inline
    #   end
    #   # 禁用 nonce 生成
    #   app.config.content_security_policy_nonce_generator = nil
    #   app.config.content_security_policy_nonce_directives = []
    # end

    #add_view :Gantt,
    #         contract_strategy: "Gantt::Views::ContractStrategy"
  end
end


requires_redmineup version_or_higher: '1.0.5' rescue raise "\n\033[31mRedmine requires newer redmineup gem version.\nPlease update with 'bundle update redmineup'.\033[0m"
require File.dirname(__FILE__) + '/../../lib/redmine_people'
require File.dirname(__FILE__) + '/../../lib/redmine_resources'

Redmineup::Settings.initialize_gem_settings
# Redmineup::Currency.add_admin_money_menu 