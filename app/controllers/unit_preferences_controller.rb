class UnitPreferencesController < ApplicationController
  before_action :set_units

  # GET /unit_preferences or /unit_preferences.json
  def index
    @unit_preference = UnitPreference.new
    @unit_preferences = UnitPreference.distinct.order(:name).pluck(:name, :description)
    authorize UnitPreference
  end

  def unit_prefs
    @unit_prefs = UnitPreference.where(unit_id: current_user.unit).order(:description)
    authorize @unit_prefs
  end

  def save_unit_prefs
    @unit_prefs = UnitPreference.where(unit_id: current_user.unit)
    authorize @unit_prefs
    @unit_prefs.update(value: false)
    if params[:unit_prefs].present?
      params[:unit_prefs].each do |unit, p|
        unit_id = unit.to_i
        p.each do |k, v|
          UnitPreference.find_by(unit_id: unit_id, name: k).update(value: true)
        end
      end
    end
    redirect_to unit_prefs_path, notice: "Preferences are updated."
  end

  # GET /unit_preferences/new
  def new
    @unit_preference = UnitPreference.new
    authorize @unit_preference
    @units = Unit.all
  end

  # POST /unit_preferences or /unit_preferences.json
  def create
    # create preference for every unit
    Unit.all.each do |unit|
      @unit_preference = UnitPreference.new(unit_preference_params)
      authorize @unit_preference
      @unit_preference.unit_id = unit.id
      unless @unit_preference.save
        @unit_preferences = UnitPreference.distinct.pluck(:name, :description)
        return
      end
    end
    flash.now[:notice] =  "Unit preference was successfully created."
    @unit_preference = UnitPreference.new
    @unit_preferences = UnitPreference.distinct.pluck(:name, :description)
  end

  def delete_preference
    @unit_preferences = UnitPreference.where(name: params[:name])
    authorize @unit_preferences

    respond_to do |format|
      if @unit_preferences.destroy_all
        format.html { redirect_to unit_preferences_path, notice: "Preference was deleted." }
      else
        format.html { render :unit_preferences_path, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def set_units
      @units = Unit.where(id: current_user.unit)
    end

    # Only allow a list of trusted parameters through.
    def unit_preference_params
      params.require(:unit_preference).permit(:name, :description, :value, :unit_id)
    end
end
