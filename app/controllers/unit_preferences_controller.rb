class UnitPreferencesController < ApplicationController
  before_action :auth_user
  before_action :set_units
  before_action :set_pref_types, only: %i[ index new edit create update]

  # GET /unit_preferences or /unit_preferences.json
  def index
    @unit_preference = UnitPreference.new
    @unit_preferences = UnitPreference.distinct.order(:name).pluck(:name, :description, :pref_type)
    authorize UnitPreference
  end

  def unit_prefs
    @unit_prefs = UnitPreference.where(unit_id: current_user.unit_ids).order(:pref_type, :description)
    authorize @unit_prefs
  end

  def save_unit_prefs
    @unit_prefs = UnitPreference.where(unit_id: current_user.unit_ids)
    authorize @unit_prefs
    @unit_prefs.where(pref_type: 'boolean').update(on_off: false)
    if params[:unit_prefs].present?
      params[:unit_prefs].each do |unit, p|
        unit_id = unit.to_i
        p.each do |k, v|
          pref = UnitPreference.find_by(unit_id: unit_id, name: k)
          if pref.pref_type == 'boolean'
            pref.update(on_off: true)
          end
          if pref.pref_type == 'time' || pref.pref_type == 'string'
            pref.update(value: v)
          end
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
        @unit_preferences = UnitPreference.distinct.pluck(:name, :description, :pref_type)
        return
      end
    end
    flash.now[:notice] =  "Unit preference was successfully created."
    @unit_preference = UnitPreference.new
    @unit_preferences = UnitPreference.distinct.pluck(:name, :description, :pref_type)
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
      @units = Unit.where(id: current_user.unit_ids)
    end

    def set_pref_types
      @pref_types = UnitPreference.pref_types.keys
    end

    # Only allow a list of trusted parameters through.
    def unit_preference_params
      params.require(:unit_preference).permit(:name, :description, :on_off, :value, :pref_type, :unit_id)
    end
end
