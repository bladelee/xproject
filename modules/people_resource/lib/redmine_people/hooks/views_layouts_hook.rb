# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2024 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

module RedminePeople
  module Hooks
=begin
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(_context = {})
        stylesheet_link_tag(:redmine_people, plugin: 'redmine_people')
      end

      render_on :view_layouts_base_body_bottom, :partial => 'common/layout_bottom'
    end
=end
  end
end
