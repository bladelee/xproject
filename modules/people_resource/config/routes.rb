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

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do

  #get "/departments", controller: "departments/departments", action: :show, as: "departments"

  resources :departments,
            controller: "departments",
            only: [:index] do
    collection do
      get "/", to: "departments#index"
      get "/edit/:id" => "departments#edit"
      get "/new", to: "departments#new"
      patch "/edit/:id" => "departments#update"
      post "/", to: "departments#create"#:add_people
      delete "/delete/:id" => "departments#delete"#:remove_person
      get 'tabs/:tab' => 'departments#show', :as => 'tabs'
      get 'load_tab' => 'departments#load_tab', :as => 'load_tab'
      #get "/upsale", to: "departments#upsale", as: :upsale
    end
  end

  # resources :people,controller: "people" do
  #   collection do
  #     get :bulk_edit, :context_menu, :edit_mails, :preview_email, :avatar
  #     get "/edit/:id" => "people#edit"
  #     put "update/:id" => "people#update"
  #     patch "update/:id" => "people#update"
  #     get :autocomplete_for_person
  #     #post "/", to: "people#add_people"
  #     post :bulk_edit, :bulk_update, :send_mails, :add_manager
  #     delete :bulk_destroy
  #     get 'calendar' => 'people_calendars#index'
  #     resources :holidays, except: :show, controller: :people_holidays, as: :people_holidays
  #   end
  # end


  namespace :departments do
    resource :menu, only: %[show index]
  end


resources :people do
  collection do
    get :bulk_edit, :context_menu, :edit_mails, :preview_email, :avatar
    get :autocomplete_for_person
    post :bulk_edit, :bulk_update, :send_mails, :add_manager
    delete :bulk_destroy
    get 'calendar' => 'people_calendars#index'
    resources :holidays, except: :show, controller: :people_holidays, as: :people_holidays
  end

  member do
    get :manager
    get :autocomplete_for_manager
    delete :destroy_avatar
    get 'tabs/:tab' => 'people#show', :as => 'tabs'
    get 'load_tab' => 'people#load_tab', :as => 'load_tab'
    delete 'remove_subordinate' => 'people#remove_subordinate', :as => 'remove_subordinate'
  end
end

resources :departments do
  member do
    get :autocomplete_for_person
    post :add_people
    post :remove_person
    get 'tabs/:tab' => 'departments#show', :as => 'tabs'
    get 'load_tab' => 'departments#load_tab', :as => 'load_tab'
  end

  get :org_chart, on: :collection
end

resources :people_settings do
  collection do
    get :autocomplete_for_user
  end
end

resources :people_queries, except: [:index]

constraints object_type: /(departments)/ do
  get 'attachments/:object_type/:object_id/edit', to: 'attachments#edit_all', as: 'departments_attachments_edit'
  patch 'attachments/:object_type/:object_id', to: 'attachments#update_all', as: 'departments_attachments'
  get 'attachments/:object_type/:object_id/download', to: 'attachments#download_all', as: 'departments_attachments_download'
end

resources :resource_bookings do
  get :issues_autocomplete, on: :collection
  post :split, on: :member
  collection do
    post :index  # 添加对 POST 请求的支持
  end  
end

resources :resource_bookings, only: [:index] do
  get :index, on: :collection, defaults: { format: :json }
end

resources :employees do
  collection do
    post :index  # 添加对 POST 请求的支持
  end
end

match 'resource_bookings/create', to: 'resource_bookings#create', via: :post
match 'resource_bookings/:id', to: 'resource_bookings#update', via: :post, id: /\d+/

get '/projects/:project_id/resource_bookings', to: 'resource_bookings#index', as: 'project_resource_bookings'
get 'resource_bookings_loads', to: 'resource_bookings#index', as: 'project_resource_bookings_loads'
end
