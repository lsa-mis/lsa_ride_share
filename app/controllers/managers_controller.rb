class ManagersController < ApplicationController
  before_action :auth_user
  before_action :set_manager, only: %i[ edit update ]
  before_action :set_units
  before_action :set_managers, only: %i[ index update_managers_mvr_status ]
  include StudentApi

  def index
  end

  def edit
  end

  def update
    if @manager.update(manager_params)
      redirect_to managers_path, notice: "The manager record was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_managers_mvr_status
    @managers.each do |manager|
      status = mvr_status(manager.uniqname)
      unless manager.update(mvr_status: status)
        redirect_to managers_path, alert: "Error updating manager record."
      end
    end
    flash.now[:notice] = "MVR status is updated."
  end

  private

    def set_manager
      @manager = Manager.find(params[:id])
      authorize @manager
    end

    def set_managers
      if params[:unit_id].present?
        unit_ids = [params[:unit_id]].to_a
      else
        unit_ids = current_user.unit_ids
      end
      programs = Program.where(unit_id: unit_ids)
      i_ids = programs.pluck(:instructor_id).uniq
      instructors = Manager.where(id: i_ids)
      p_ids = programs.pluck(:id)
      managers = Manager.joins(:programs).where('managers_programs.program_id IN (?)', p_ids)
      @managers = (instructors + managers).uniq.sort_by(&:uniqname)
      authorize Manager
    end

    def set_units
      if is_admin?(current_user)
      @units = Unit.where(id: current_user.unit_ids).order(:name)
      elsif is_manager?(current_user)
        manager = Manager.find_by(uniqname: current_user.uniqname)
        @units = Unit.where(id: manager.programs.pluck(:unit_id).uniq).order(:name)
      else
        @units = Unit.all
      end
    end

    # Only allow a list of trusted parameters through.
    def manager_params
      params.require(:manager).permit(:uniqname, :first_name, :last_name, :program_id,
        :mvr_status, :canvas_course_complete_date, :meeting_with_admin_date, :phone_number)
    end

end
