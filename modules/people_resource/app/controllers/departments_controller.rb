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
#module ::Departments
class DepartmentsController < ApplicationController
    include Layout
    include QueriesHelper
    before_action :find_department, :except => [:index, :create, :new, :org_chart]
    #before_action :authorize_people, :except => [:index, :show, :load_tab, :autocomplete_for_person, :org_chart]
    # before_action :load_department_events, :load_department_attachments, :only => [:show, :load_tab]

    #helper :attachments
    menu_item :people_resources

    def index
      @departments = Department.all
      render layout: "global"
    end


    def edit
      if params[:id]
        @department = Department.find(params[:id])
        puts "------------------------------@department = #{@department.as_json}"
        puts "------------------------------@department.head_id = #{@department.head_id}"
        response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
        response.headers["Pragma"] = "no-cache"
        response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
        @department
      end
      render layout: "global"
    end

    def new
      @department = Department.new
      render layout: "global"
    end

    def show
      render layout: "global"
    end

    def update
      @department = Department.find(params[:id])
      @department.name = params[:department][:name]
      @department.background = params[:department][:background]
      @department.head_id = params[:department][:head_id]
      @department.parent_id = params[:department][:parent_id]
      if @department.save
        @department.head.department = @department if @department.head

        # attachments = Attachment.attach_files(@department, params.respond_to?(:to_unsafe_hash) ? params.to_unsafe_hash['attachments'] : params['attachments'])
        # render_attachment_warning_if_needed(@department)

        respond_to do |format|
          format.html { redirect_to :action => 'index', :id => @department }
          #format.api  { head :ok }
        end
      else
        respond_to do |format|
          format.html { render layout: "global", :action => 'edit' }
          #format.api  { render_validation_errors(@department) }
        end
      end
    end

    def destroy
      if @department.destroy
        flash[:notice] = l(:notice_successful_delete)
        if params[:from] == 'people_settings'
          respond_to do |format|
            format.html { redirect_to :controller => 'people_settings', :action => 'index', :tab => 'departments' }
            format.api { render_api_ok }
          end
        else
          redirect_to :action => 'index'
        end
      else
        flash[:error] = l(:notice_unsuccessful_save)
      end
    end

    def create
      @department = Department.new
      #@department.attributes = params[:department]
      @department.name = params[:department][:name]
      @department.background = params[:department][:background]
      @department.head_id = params[:department][:head_id]
      @department.parent_id = params[:department][:parent_id]
      if @department.save
        @department.head.department = @department if @department.head

        respond_to do |format|
          format.html { redirect_to :controller => 'departments', :action => 'index', :id => @department, :tab => 'people' }
          # format.html do
          #   redirect_to edit_department_path(@department, tab: 'people', _t: Time.now.to_i)
          # end
          #format.html { redirect_to :action => 'show', :id => @department }
          # format.html { redirect_to :controller => "people_settings", :action => "index", :tab => "departments" }
          #format.api  { head :ok }
        end
      else
        respond_to do |format|
          format.html { render layout: "global", :action => 'new' }
          #format.api  { render_validation_errors(@department) }
        end
      end
    end

    def add_people
      @people = PeopleInformation.where(:user_id => params[:person_id] || params[:person_ids])
      @department.people_information << @people if request.post?
      # @department.people_information.save
      respond_to do |format|
        format.html { redirect_to :controller => 'departments', :action => 'edit', 
                                  :id => @department, :tab => 'people',  
                                  format: :html, _t: Time.now.to_i  }
        format.js
        # format.api { render_api_ok }
      end
    end

    def remove_person
      @department.people_information.delete(PeopleInformation.find(params[:person_id])) 
      # @department.people_information.save
      respond_to do |format|
        # format.html { redirect_to :controller => 'departments', :action => 'edit', :id => @department, :tab => 'people' }
        format.html { redirect_to edit_department_path(@department, tab: 'people'), format: :html, _t: Time.now.to_i  } 
        format.js
        # format.api { render_api_ok }
      end
    end  


    def delete
      @department = Department.find(params[:id])
      @department.delete if request.delete?
      respond_to do |format|
        format.html { redirect_to :controller => 'departments', :action => 'index', :id => @department, :tab => 'people' }
        #format.js
        #format.api { render_api_ok }
      end
    end

    def autocomplete_for_person
      puts '-----------------------department_autocomplete_for_person------------------------------'
      @people = Person.active.where(:type => 'User').not_in_department(@department).like(params[:q]).limit(100)
      render :layout => false
    end

    def load_tab
    end

    def org_chart
      User.current.allowed_people_to?(:manage_departments, @person) ||
      User.current.allowed_people_to?(:view_people, @person) ||
      deny_access
    end

    private

    def find_department
      @department = Department.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize_people
      User.current.allowed_people_to?(:manage_departments, @person) || deny_access
    end

    def load_department_attachments
      #@department_attachments = @department.attachments
    end

    def load_department_events
      #events = Redmine::Activity::CrmFetcher.new(User.current, :author => @department.people_of_branch_department).events(nil, nil, :limit => 10)
      #@events_by_day = events.group_by(&:event_date)
    end

end
#end
