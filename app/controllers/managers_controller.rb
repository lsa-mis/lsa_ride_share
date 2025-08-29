class ManagersController < ApplicationController
  before_action :auth_user
  before_action :set_manager, only: %i[ edit update destroy]
  before_action :set_units
  before_action :set_managers, only: %i[ index update_managers_mvr_status ]
  include StudentApi

  def index
  end

  def edit
    @mvr_status = @manager.mvr_status.remove("Approved until ").to_date
  end

  def update
    if params[:mvr_status].present? && params[:mvr_status] != ""
      mvr_status = "Approved until " + params[:mvr_status]
    else
      mvr_status = ""
    end
    if @manager.update(manager_params)
      @manager.update(mvr_status: mvr_status)
      redirect_to managers_path, notice: "The manager record was updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update_managers_mvr_status
    @managers.each do |manager|
      result = mvr_status(manager.uniqname)
      if result['success']
        unless manager.update(mvr_status: result['mvr_status'])
          redirect_to managers_path, alert: "Error updating manager record."
        end
      else
        flash.now[:alert] = "Error retrieving MVR status for #{manager.uniqname}: #{result['error']}"
        set_managers
        return
      end
    end
    flash.now[:notice] = "MVR status is updated."
  end

  def destroy
    begin
      @manager.destroy
      respond_to do |format|
        format.html { redirect_to managers_url, notice: "Manager was successfully deleted." }
        format.json { head :no_content }
      end
    rescue StandardError => e
      flash.now[:alert] = "Manager has reservations and can't be removed: " + e.message
      set_managers
      return
    end
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
        unit_ids = session[:unit_ids]
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
      if is_admin?
      @units = Unit.where(id: session[:unit_ids]).order(:name)
      elsif is_manager?
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
