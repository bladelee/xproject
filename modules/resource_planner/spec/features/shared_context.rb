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

RSpec.shared_context "with resource planner full access" do
  shared_let(:project) do
    create(:project)
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %w[
             view_work_packages edit_work_packages add_work_packages
             view_resource_planner manage_resource_planner
             save_queries manage_public_queries
             work_package_assigned
           ] })
  end

  let(:resource_planner) { Pages::ResourcePlanner.new project }
  let(:filters) { resource_planner.filters }

  current_user { user }
end
