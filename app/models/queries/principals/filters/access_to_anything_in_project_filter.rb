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

class Queries::Principals::Filters::AccessToAnythingInProjectFilter < Queries::Principals::Filters::PrincipalFilter
  def allowed_values
    Project
    .visible(User.current)
    .active
    .pluck(:name, :id)
  end

  def type
    :list_optional
  end

  def self.key
    :access_to_anything_in_project
  end

  def scope
    case operator
    when "="
      visible_scope.in_anything_in_project(values)
    when "!"
      visible_scope.not_in_anything_in_project(values)
    when "*"
      member_included_scope.where.not(members: { id: nil })
    when "!*"
      member_included_scope.where.not(id: Member.distinct(:user_id).select(:user_id))
    end
  end

  private

  def visible_scope
    Principal.visible(User.current)
  end

  def member_included_scope
    visible_scope
      .includes(:members)
      .merge(Member.where.not(project: nil))
  end
end