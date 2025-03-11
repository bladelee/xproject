# frozen_string_literal: true

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
require_relative "../support/pages/resource_planner"
require_relative "../../../../spec/features/views/shared_examples"

RSpec.describe "Resource planner query handling", :js, with_ee: %i[resource_planner_view] do
  shared_let(:type_task) { create(:type_task) }
  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:project) do
    create(:project,
           enabled_module_names: %w[work_package_tracking resource_planner_view],
           types: [type_task, type_bug])
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %w[
             view_work_packages
             edit_work_packages
             save_queries
             save_public_queries
             view_resource_planner
             manage_resource_planner
           ] })
  end

  shared_let(:task) do
    create(:work_package,
           project:,
           type: type_task,
           assigned_to: user,
           start_date: Time.zone.today - 1.day,
           due_date: Time.zone.today + 1.day,
           subject: "A task for the user")
  end
  shared_let(:bug) do
    create(:work_package,
           project:,
           type: type_bug,
           assigned_to: user,
           start_date: Time.zone.today - 1.day,
           due_date: Time.zone.today + 1.day,
           subject: "A bug for the user")
  end

  let(:resource_planner) { Pages::ResourcePlanner.new project }
  let(:work_package_page) { Pages::WorkPackagesTable.new project }
  let(:query_title) { Components::WorkPackages::QueryTitle.new }
  let(:query_menu) { Components::WorkPackages::QueryMenu.new }
  let(:filters) { resource_planner.filters }

  current_user { user }

  before do
    resource_planner.visit!

    resource_planner.add_assignee user
    loading_indicator_saveguard
    resource_planner.expect_assignee user
    resource_planner.within_lane(user) do
      resource_planner.expect_event bug
      resource_planner.expect_event task
    end
  end

  it "allows saving the resource planner" do
    filters.expect_filter_count("1")
    filters.open

    filters.add_filter_by("Type", "is (OR)", [type_bug.name])

    filters.expect_filter_count("2")

    resource_planner.within_lane(user) do
      resource_planner.expect_event bug
      resource_planner.expect_event task, present: false
    end

    query_title.expect_changed

    query_title.press_save_button

    resource_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_create"))
  end

  it "shows only resource planner queries" do
    # Go to resource planner where no query is shown, only the create option
    query_menu.expect_no_menu_entry
    expect(page).to have_test_selector("resource-planner--create-button")

    # Change filter
    filters.open
    filters.add_filter_by("Type", "is (OR)", [type_bug.name])
    filters.expect_filter_count("2")

    # Save current filters
    query_title.expect_changed
    query_title.rename "I am your Query"
    resource_planner.expect_and_dismiss_toaster(message: I18n.t("js.notice_successful_create"))

    # The saved query appears in the side menu...
    query_menu.expect_menu_entry "I am your Query"

    # .. but not in the work packages module
    work_package_page.visit!
    query_menu.expect_menu_entry_not_visible "I am your Query"
  end

  it_behaves_like "module specific query view management" do
    let(:module_page) { resource_planner }
    let(:default_name) { "Unnamed resource planner" }
    let(:initial_filter_count) { 1 }
  end
end
