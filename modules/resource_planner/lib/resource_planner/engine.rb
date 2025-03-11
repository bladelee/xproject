# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2021-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Resource
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

module ResourcePlanner
  class Engine < ::Rails::Engine
    engine_name :resource_planner

    include OpenProject::Plugins::ActsAsOpEngine

    register "resource_planner",
             author_url: "https://www.xproject.org",
             bundled: true,
             settings: {} do
      project_module :resource_planner_view, dependencies: :work_package_tracking, enterprise_feature: true do
        permission :view_resource_planner,
                   { "resource_planner/resource_planner": %i[index show upsale overview] },
                   permissible_on: :project,
                   dependencies: %i[view_work_packages],
                   contract_actions: { resource_planner: %i[read] }
        permission :manage_resource_planner,
                   { "resource_planner/resource_planner": %i[index show new create destroy upsale] },
                   permissible_on: :project,
                   dependencies: %i[view_resource_planner
                                    add_work_packages
                                    edit_work_packages
                                    save_queries
                                    manage_public_queries],
                   contract_actions: { resource_planner: %i[create update destroy] }
      end

      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
        User.current.allowed_in_any_project?(:view_resource_planner)
      end

      menu :global_menu,
           :resource_planners,
           { controller: "/resource_planner/resource_planner", action: :overview },
           caption: :"resource_planner.label_resource_planner_plural",
           before: :boards,
           after: :calendar_view,
           icon: "team-planner",
           if: should_render_global_menu_item,
           enterprise_feature: "resource_planner_view"

      menu :project_menu,
           :resource_planner_view,
           { controller: "/resource_planner/resource_planner", action: :index },
           caption: :"resource_planner.label_resource_planner_plural",
           after: :work_packages,
           icon: "team-planner",
           enterprise_feature: "resource_planner_view"           


      menu :project_menu,
           :resource_planner_menu,
           { controller: "/resource_planner/resource_planner", action: :index },
           parent: :resource_planner_view,
           partial: "resource_planner/resource_planner/menu",
           last: true,
           caption: :"resource_planner.label_resource_planner_plural"

      menu :top_menu,
           :resource_planners, { controller: "/resource_planner/resource_planner", action: :overview },
           context: :modules,
           caption: :"resource_planner.label_resource_planner_plural",
           before: :boards,
           after: :calendar_view,
           icon: "team-planner",
           if: should_render_global_menu_item,
           enterprise_feature: "resource_planner_view"               

    end

    add_view :ResourcePlanner,
             contract_strategy: "ResourcePlanner::Views::ContractStrategy"
  end
end
