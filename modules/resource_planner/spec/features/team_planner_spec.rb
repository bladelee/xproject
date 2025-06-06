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

RSpec.describe "Resource planner",
               :js,
               with_ee: %i[resource_planner_view],
               with_settings: { start_of_week: 1 } do
  include_context "with resource planner full access"

  it "hides the internally used filters" do
    visit project_path(project)

    within "#main-menu" do
      click_link "Resource planners"
    end

    expect(page).to have_content "There is currently nothing to display."
    click_on "Create", match: :first

    resource_planner.expect_title

    filters.expect_filter_count("1")
    filters.open

    filters.open_available_filter_list
    filters.expect_available_filter "Author", present: true
    filters.expect_available_filter "Subject", present: true
    filters.expect_available_filter "Finish date", present: false
    filters.expect_available_filter "Start date", present: false
    filters.expect_available_filter "Assignee", present: false
    filters.expect_available_filter "Assignee or belonging group", present: false
    filters.expect_available_filter "Assignee's group", present: false
    filters.expect_available_filter "Assignee's role", present: false
  end

  context "with an assigned work package", with_settings: { working_days: [1, 2, 3, 4, 5] } do
    let!(:other_user) do
      create(:user,
             firstname: "Other",
             lastname: "User",
             member_with_permissions: { project => %w[
               view_work_packages edit_work_packages view_resource_planner manage_resource_planner
             ] })
    end
    let!(:user_outside_project) { create(:user, firstname: "Not", lastname: "In Project") }
    let(:type_task) { create(:type_task) }
    let(:type_bug) { create(:type_bug) }
    let(:closed_status) { create(:status, is_closed: true) }

    let!(:other_task) do
      create(:work_package,
             project:,
             type: type_task,
             assigned_to: other_user,
             start_date: Time.zone.today.monday + 1.day,
             due_date: Time.zone.today.monday + 3.days,
             subject: "A task for the other user")
    end
    let!(:other_bug) do
      create(:work_package,
             project:,
             type: type_bug,
             assigned_to: other_user,
             start_date: Time.zone.today.monday + 1.day,
             due_date: Time.zone.today.monday + 3.days,
             subject: "Another task for the other user")
    end
    let!(:closed_bug) do
      create(:work_package,
             project:,
             type: type_bug,
             assigned_to: other_user,
             status: closed_status,
             start_date: Time.zone.today.monday + 1.day,
             due_date: Time.zone.today.monday + 3.days,
             subject: "Closed bug")
    end
    let!(:user_bug) do
      create(:work_package,
             project:,
             type: type_bug,
             assigned_to: user,
             start_date: Time.zone.today - 10.days,
             due_date: Time.zone.today + 20.days,
             subject: "A task for the logged in user")
    end
    let!(:user_bug_next_week) do
      create(:work_package,
             project:,
             type: type_bug,
             assigned_to: user,
             start_date: Time.zone.today.monday + 7.days,
             due_date: Time.zone.today.monday + 12.days,
             subject: "A task for the logged in user in the next week")
    end
    let!(:user_bug_last_week) do
      create(:work_package,
             project:,
             type: type_bug,
             assigned_to: user,
             start_date: Time.zone.today.monday - 7.days,
             due_date: Time.zone.today.monday - 5.days,
             subject: "A task for the logged in user in the last week")
    end
    let!(:user_bug_on_weekend) do
      create(:work_package,
             project:,
             type: type_bug,
             assigned_to: user,
             start_date: Time.zone.today.monday + 5.days,
             due_date: Time.zone.today.monday + 6.days,
             subject: "A task for the logged in user on the weekend")
    end

    before do
      project.types << type_bug
      project.types << type_task
    end

    it "renders a resource planner displaying work packages by assignee and date" do
      resource_planner.visit!

      resource_planner.title

      resource_planner.wait_for_loaded
      resource_planner.expect_empty_state
      resource_planner.expect_assignee(user, present: false)
      resource_planner.expect_assignee(other_user, present: false)

      resource_planner.add_assignee user.name

      resource_planner.expect_empty_state(present: false)

      resource_planner.add_assignee other_user.name

      resource_planner.expect_assignee user
      resource_planner.expect_assignee other_user

      # Starting on the "Work week" by default means that
      # work packages on the weekend as well as in the last or upcoming week are not displayed.
      # Those work packages that are displayed, are displayed in the row of their assignee.

      resource_planner.within_lane(user) do
        resource_planner.expect_event user_bug
        resource_planner.expect_event user_bug_next_week, present: false
        resource_planner.expect_event user_bug_last_week, present: false
        resource_planner.expect_event user_bug_on_weekend, present: false
      end

      resource_planner.within_lane(other_user) do
        resource_planner.expect_event other_task
        resource_planner.expect_event other_bug
        resource_planner.expect_event closed_bug
      end

      # Switching to the '1-week' view means that
      # work packages on the weekend are displayed now but
      # those outside of the current week are still hidden.
      resource_planner.switch_view_mode("1-week")

      resource_planner.within_lane(user) do
        resource_planner.expect_event user_bug
        resource_planner.expect_event user_bug_next_week, present: false
        resource_planner.expect_event user_bug_last_week, present: false
        resource_planner.expect_event user_bug_on_weekend
      end

      # Switching to the '2-week' view means that
      # work packages on the weekend and those of the upcoming week are displayed.
      # Those in the last week are still hidden.

      resource_planner.switch_view_mode("2-week")

      resource_planner.within_lane(user) do
        resource_planner.expect_event user_bug
        resource_planner.expect_event user_bug_next_week
        resource_planner.expect_event user_bug_last_week, present: false
        resource_planner.expect_event user_bug_on_weekend
      end

      # Add filter for type task
      filters.expect_filter_count("1")
      filters.open

      filters.add_filter_by("Type", "is (OR)", [type_task.name])
      filters.expect_filter_by("Type", "is (OR)", [type_task.name])
      filters.expect_filter_count("2")

      resource_planner.expect_assignee(user, present: true)
      resource_planner.expect_assignee(other_user, present: true)

      resource_planner.within_lane(other_user) do
        resource_planner.expect_event other_task
        resource_planner.expect_event other_bug, present: false
        resource_planner.expect_event closed_bug, present: false
      end

      # Open the split view for that task and change to bug
      split_view = resource_planner.open_split_view_by_info_icon(other_task)
      split_view.edit_field(:type).update(type_bug)
      split_view.expect_and_dismiss_toaster(message: "Successful update.")

      resource_planner.expect_assignee(user, present: true)
      resource_planner.expect_assignee(other_user, present: true)

      resource_planner.expect_empty_state(present: false)
    end

    it "can add and remove assignees" do
      resource_planner.visit!

      resource_planner.expect_empty_state
      resource_planner.expect_assignee(user, present: false)
      resource_planner.expect_assignee(other_user, present: false)

      resource_planner.add_assignee user.name

      resource_planner.expect_empty_state(present: false)
      resource_planner.expect_assignee(user)
      resource_planner.expect_assignee(other_user, present: false)

      resource_planner.add_assignee other_user.name

      resource_planner.expect_assignee(user)
      resource_planner.expect_assignee(other_user)

      resource_planner.remove_assignee(user)

      resource_planner.expect_assignee(user, present: false)
      resource_planner.expect_assignee(other_user)

      resource_planner.remove_assignee(other_user)

      resource_planner.expect_assignee(user, present: false)
      resource_planner.expect_assignee(other_user, present: false)
      resource_planner.expect_empty_state

      # Try one more time to make sure deleting the full filter didn't kill the functionality
      resource_planner.add_assignee user.name

      resource_planner.expect_assignee(user)
      resource_planner.expect_assignee(other_user, present: false)
    end

    it "filters possible assignees correctly" do
      resource_planner.visit!

      resource_planner.search_assignee(user_outside_project.name)

      expect(page).to have_css(".ng-option-disabled", text: "No items found")

      retry_block do
        resource_planner.select_user_to_add user.name
      end

      resource_planner.expect_assignee(user)

      resource_planner.search_assignee user.name

      expect(page).to have_css(".ng-option-disabled", text: "No items found")
    end

    context "when the page size is smaller than the number of assignees" do
      before do
        allow(Setting)
          .to receive(:per_page_options_array)
          .and_return([1])
      end

      it "renders assignees and assignee dropdown correctly" do
        resource_planner.visit!
        resource_planner.wait_for_loaded

        # Render all the available users in the select dropdown regardless of the page size
        resource_planner.click_add_user

        resource_planner.expect_user_selectable user
        resource_planner.expect_user_selectable other_user

        resource_planner.add_assignee user
        resource_planner.add_assignee other_user

        resource_planner.save_as("TP1")
        page.refresh
        resource_planner.wait_for_loaded

        # Render all the available users in the resource planner regardless of the page size
        resource_planner.expect_assignee user
        resource_planner.expect_assignee other_user

        # Do not render any available users in the select
        resource_planner.click_add_user
        resource_planner.expect_user_selectable user, present: false
        resource_planner.expect_user_selectable other_user, present: false
      end
    end
  end

  context "with a readonly work package" do
    let(:readonly_status) { create(:status, is_readonly: true) }

    let!(:blocked_task) do
      create(:work_package,
             project:,
             assigned_to: user,
             status: readonly_status,
             start_date: Time.zone.today - 1.day,
             due_date: Time.zone.today + 1.day,
             subject: "A blocked task")
    end

    it "disables editing on readonly tasks", with_ee: %i[resource_planner_view readonly_work_packages] do
      resource_planner.visit!

      resource_planner.wait_for_loaded
      resource_planner.expect_empty_state
      resource_planner.expect_assignee(user, present: false)

      resource_planner.add_assignee user.name

      resource_planner.expect_empty_state(present: false)
      resource_planner.expect_assignee user

      resource_planner.within_lane(user) do
        resource_planner.expect_event blocked_task
        resource_planner.expect_resizable blocked_task, resizable: false
      end
    end
  end
end
