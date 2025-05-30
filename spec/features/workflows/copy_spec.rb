#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
#++

require "spec_helper"

RSpec.describe "Workflow copy" do
  let(:role) { create(:project_role) }
  let(:type) { create(:type) }
  let(:admin)  { create(:admin) }
  let(:statuses) { (1..2).map { |_i| create(:status) } }
  let!(:workflow) do
    create(:workflow, role_id: role.id,
                      type_id: type.id,
                      old_status_id: statuses[0].id,
                      new_status_id: statuses[1].id,
                      author: false,
                      assignee: false)
  end

  current_user { admin }

  before do
    visit url_for(controller: "/workflows", action: :copy)
  end

  it "shows existing types and roles" do
    select(role.name, from: :source_role_id)
    within("#source_role_id") do
      expect(page).to have_content(role.name)
      expect(page).to have_content("--- #{I18n.t(:actionview_instancetag_blank_option)} ---")
    end
    within("#source_type_id") do
      expect(page).to have_content(type.name)
      expect(page).to have_content("--- #{I18n.t(:actionview_instancetag_blank_option)} ---")
    end
  end
end
