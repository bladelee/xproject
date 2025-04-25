class StationsController < ApplicationController
  layout "admin"
  before_action :require_admin
  before_action :authorize_global, except: %i[show]
  before_action :find_station, only: %i[show edit update deletion_info destroy]

  def index
    @stations = Station.order(:position)

    respond_to do |format|
      format.html do
        render layout: !request.xhr?
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render layout: "no_menu" }
    end
  end

  def new
    @station = Station.new
  end

  def edit; end

  def create
    @station = Station.new(permitted_params.station)

    if @station.save
      flash[:notice] = t(:notice_successful_create)
      redirect_to(params[:continue] ? new_station_path : stations_path)
    else
      render action: :new
    end
  end

  def update
    if @station.update(permitted_params.station)
      flash[:notice] = t(:notice_successful_update)
      redirect_to stations_path
    else
      render action: :edit
    end
  end

  def deletion_info
    respond_to :html
  end

  def destroy
    if @station.destroy
      flash[:notice] = t(:notice_successful_delete)
    else
      flash[:error] = t(:error_can_not_delete_station)
    end

    redirect_to stations_path
  end

  private

  def find_station
    @station = Station.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def default_breadcrumb
    if action_name == "index"
      t("label_station_plural")
    else
      ActionController::Base.helpers.link_to(t("label_station_plural"), stations_path)
    end
  end

  def show_local_breadcrumb
    true
  end
end 