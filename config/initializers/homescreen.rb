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

require "open_project/static/homescreen"
require "open_project/static/links"

OpenProject::Static::Homescreen.manage :blocks do |blocks|
  blocks.push(
    # {
    #   partial: "welcome",
    #   if: Proc.new { Setting.welcome_on_homescreen? && Setting.welcome_text.present? }
    # },
    {
      partial: "projects"
    },
    # {
    #   partial: "new_features",
    #   if: Proc.new { OpenProject::Configuration.show_community_links? }
    # },
    # {
    #   partial: "users",
    #   if: Proc.new { User.current.admin? }
    # },
    {
      partial: "my_account",
      if: Proc.new { User.current.logged? }
    },
    # {
    #   partial: "news",
    #   if: Proc.new { !@news.empty? }
    # },
    # {
    #   partial: "community",
    #   if: Proc.new { EnterpriseToken.show_banners? || OpenProject::Configuration.show_community_links? }
    # },
    # {
    #   partial: "administration",
    #   if: Proc.new { User.current.admin? }
    # },
    # {
    #   partial: "upsale",
    #   if: Proc.new { EnterpriseToken.show_banners? }
    # }
  )
end

OpenProject::Static::Homescreen.manage :links do |links|
  link_hash = OpenProject::Static::Links.links

  links.push(
    {
      label: :user_guides,
      icon: "icon-context icon-rename",
      url: link_hash[:user_guides][:href]
    },
    {
      label: :glossary,
      icon: "icon-context icon-glossar",
      url: link_hash[:glossary][:href]
    },
    {
      label: :shortcuts,
      icon: "icon-context icon-shortcuts",
      url: link_hash[:shortcuts][:href]
    },
    {
      label: :forums,
      icon: "icon-context icon-forums",
      url: link_hash[:forums][:href]
    }
  )

  if impressum_link = link_hash[:impressum]
    links.push({
                 label: :impressum,
                 url: impressum_link[:href],
                 icon: "icon-context icon-info1"
               })
  end
end
