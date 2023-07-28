class UnitsController < ApplicationController
  before_action :auth_user
  before_action :set_unit, only: %i[ edit update destroy ]

  # GET /units or /units.json
  def index
    @unit = Unit.new
    @units = Unit.all
    authorize Unit
  end

  # GET /units/new
  def new
    @unit = Unit.new
    authorize @unit
  end

  # GET /units/1/edit
  def edit
  end

  # POST /units or /units.json
  def create
    @unit = Unit.new(unit_params)
    authorize @unit
    if @unit.save
      # create preferences for the unit
      prefs = UnitPreference.distinct.pluck(:name, :description, :pref_type)
      prefs.each do |name, descr, pref_type|
        if pref_type == "boolean"
          unless UnitPreference.create(name: name, description: descr, pref_type: pref_type, on_off: false, unit_id: @unit.id)
            @units = Unit.all
            return
          end
        else
          unless UnitPreference.create(name: name, description: descr, pref_type: pref_type, unit_id: @unit.id)
            @units = Unit.all
            return
          end 
        end
      end
      @unit = Unit.new
      flash.now[:notice] = "Unit was successfully created."
    end
    @units = Unit.all
  end

  # PATCH/PUT /units/1 or /units/1.json
  def update
    respond_to do |format|
      if @unit.update(unit_params)
        @unit = Unit.new
        @units = Unit.all
        format.html { redirect_to units_path, notice: "Unit was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /units/1 or /units/1.json
  def destroy
    if @unit.programs.present? || @unit.cars.present?
      flash.now[:alert] = "he Unit can't be deleted because it has programs or cars."
      @units = Unit.all
      return
    else
      if @unit.destroy
        flash.now[:notice] = "Unit was deleted."
      else
        @units = Unit.all
        render :aindex, status: :unprocessable_entity
      end
    end
    @units = Unit.all
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit
      @unit = Unit.find(params[:id])
      authorize @unit
    end

    # Only allow a list of trusted parameters through.
    def unit_params
      params.require(:unit).permit(:name, :ldap_group)
    end
end
