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

RSpec.describe "Resource planner", :js, with_ee: %i[resource_planner_view] do
  include_context "with resource planner full access"

  it "allows switching of view modes", with_settings: { working_days: [1, 2, 3, 4, 5] } do
    resource_planner.visit!

    resource_planner.expect_empty_state
    resource_planner.add_assignee user.name

    resource_planner.expect_view_mode "Work week"
    expect(page).to have_css(".fc-timeline-slot-frame", count: 5)

    # weekly: Expect 7 slots
    resource_planner.switch_view_mode "1-week"
    expect(page).to have_css(".fc-timeline-slot-frame", count: 7)

    # 2 weeks: expect 14 slots
    resource_planner.switch_view_mode "2-week"
    expect(page).to have_css(".fc-timeline-slot-frame", count: 14)

    start_of_week = Time.zone.today.beginning_of_week(:sunday)
    start_date = start_of_week.strftime("%d %a")
    end_date = (start_of_week + 13.days).strftime("%d %a")

    expect(page).to have_css(".fc-timeline-slot", text: start_date)
    expect(page).to have_css(".fc-timeline-slot", text: end_date)

    # Click next button, advance one week
    find(".fc-next-button").click

    start_of_week = (Time.zone.today + 1.week).beginning_of_week(:sunday)
    start_date = start_of_week.strftime("%d %a")
    end_date = (start_of_week + 13.days).strftime("%d %a")

    expect(page).to have_css(".fc-timeline-slot", text: start_date)
    expect(page).to have_css(".fc-timeline-slot", text: end_date)
  end
end
