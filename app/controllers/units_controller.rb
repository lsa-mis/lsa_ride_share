class UnitsController < ApplicationController
  before_action :set_unit, only: %i[ show edit update destroy ]

  # GET /units or /units.json
  def index
    @unit = Unit.new
    @units = Unit.all
    authorize Unit
  end

  # GET /units/1 or /units/1.json
  def show
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
      prefs = UnitPreference.distinct.pluck(:name, :description)
      prefs.each do |name, descr|
        UnitPreference.create(name: name, description: descr, unit_id: @unit.id)
      end
      @unit = Unit.new
      flash.now[:notice] = "Unit was successfully created."
    end
    @units = Unit.all
  end

  # PATCH/PUT /units/1 or /units/1.json
  def update
    if @unit.update(unit_params)
      @unit = Unit.new
      redirect_to units_path, notice: "Unit was successfully updated."
    end
  end

  # DELETE /units/1 or /units/1.json
  def destroy
    if @unit.destroy
      flash.now[:notice] = "Unit was removed."
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
