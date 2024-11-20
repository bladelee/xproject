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

module OpenProject::PeopleResource
  class Engine < ::Rails::Engine
    engine_name :openproject_people_resource

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-people_resource",
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

    #add_view :Gantt,
    #         contract_strategy: "Gantt::Views::ContractStrategy"
  end
end
