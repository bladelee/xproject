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

class Station < ApplicationRecord
  #default_scope { order_by_position }
  #before_destroy :check_integrity
  #include ::Scopes::Scoped
  acts_as_list

  validates :name,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { maximum: 256 }

  def to_s; name end

  def self.visible(user = User.current)
    if user.admin?
      all
    else
      none
    end
  end

  def self.xvisible(user = User.current)
    puts "visible called"
    if user.allowed_globally?(:manage_placeholder_user) ||
       user.allowed_in_any_project?(:manage_members)
      all
    else
      in_visible_project(user)
    end
  end

  ##
  # Overrides cache key so that changes to EE state are reflected
=begin
  def cache_key
    super + "/" + can_readonly?.to_s
  end
=end

=begin
  private

  def check_integrity
    raise "Can't delete status" if WorkPackage.where(station_id: id).exists?
  end
=end

end
