#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
#++

require "spec_helper"
require_relative "shared_context"

RSpec.describe "Resource planner index", :js, :with_cuprite, with_ee: %i[resource_planner_view] do
  shared_let(:project) do
    create(:project)
  end

  shared_let(:user_with_full_permissions) do
    create(:user,
           member_with_permissions: { project => %w[
             view_work_packages edit_work_packages add_work_packages
             view_resource_planner manage_resource_planner
             save_queries manage_public_queries
             work_package_assigned
           ] })
  end
  shared_let(:user_with_limited_permissions) do
    create(:user,
           firstname: "Bernd",
           member_with_permissions: { project => %w[view_work_packages view_resource_planner] })
  end

  let(:resource_planner) { Pages::ResourcePlanner.new(project) }

  let(:current_user) { user_with_full_permissions }

  before do
    login_as current_user
    visit project_resource_planners_path(project)
  end

  it "shows a create button" do
    resource_planner.expect_create_button
  end

  it "can create an action through the sidebar" do
    find_test_selector("resource-planner--create-button").click

    resource_planner.expect_no_toaster
    resource_planner.expect_title
  end

  context "with no views" do
    it "shows an empty index action" do
      resource_planner.expect_no_views_rendered
    end
  end

  context "with existing views" do
    shared_let(:query) do
      create(:public_query, user: user_with_full_permissions, project:)
    end
    shared_let(:resource_plan) do
      create(:view_resource_planner, query:)
    end

    shared_let(:other_query) do
      create(:public_query, user: user_with_full_permissions, project:)
    end
    shared_let(:other_resource_plan) do
      create(:view_resource_planner, query: other_query)
    end

    shared_let(:private_query) do
      create(:private_query, user: user_with_full_permissions, project:)
    end
    shared_let(:private_resource_plan) do
      create(:view_resource_planner, query: private_query)
    end

    context "as a user with full permissions within a project" do
      let(:current_user) { user_with_full_permissions }

      it "shows views" do
        resource_planner.expect_views_rendered(query, private_query, other_query)
      end

      it "shows management buttons" do
        resource_planner.expect_delete_buttons_for(query, private_query, other_query)
      end

      context "and as the author of a private view" do
        it "shows my private view" do
          resource_planner.expect_views_rendered(query, private_query, other_query)

          resource_planner.expect_delete_buttons_for(query, private_query, other_query)
        end
      end
    end

    context "as a user with limited permissions within a project" do
      let(:current_user) { user_with_limited_permissions }

      it "does not show the management buttons" do
        resource_planner.expect_no_create_button
        resource_planner.expect_no_delete_buttons_for(query, other_query)
      end

      it "shows public views only" do
        resource_planner.expect_views_rendered(query, other_query)
      end
    end
  end
end
