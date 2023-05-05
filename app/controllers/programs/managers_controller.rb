class Programs::ManagersController < ApplicationController
  before_action :set_manager_program
  before_action :set_manager, only: %i[ new edit_program_managers ]
  include ManagerApi

  def new
  end

  def edit_program_managers
  end

  def create
    if params[:manager_id].present?
      @manager = Manager.find(params[:manager_id])
      authorize @manager
      if @manager_program.managers << @manager
        @manager = Manager.new
        flash[:notice] = "The manager was added."
      end
    else
      uniqname = manager_params[:uniqname]
      result = get_name(uniqname, @manager_program)
      @manager = Manager.new(manager_params)
      authorize @manager
      if result['valid'] 
        @manager.first_name = result['first_name']
        @manager.last_name = result['last_name']
        if @manager.save
          @manager_program.managers << @manager
          @manager = Manager.new
          flash.now[:notice] = "Manager is added." + result['note']
        end
      else
        flash.now[:alert] = result['note']
        return
      end
    end
  end

  def remove_manager_from_program
    @manager = Manager.find(params[:id])
    authorize @manager
    if @manager_program.managers.delete(@manager)
      flash.now[:notice] = "The manager was removed from the program."
    end
    @manager = Manager.new
  end

  private

    def set_manager_program
      @manager_program = Program.find(params[:program_id])
    end

    def set_manager
      @manager = Manager.new
      authorize @manager
    end

    # Only allow a list of trusted parameters through.
    def manager_params
      params.require(:manager).permit(:uniqname, :first_name, :last_name, :program_id)
    end

end