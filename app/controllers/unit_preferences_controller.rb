class UnitPreferencesController < ApplicationController
  before_action :set_unit_preference, only: %i[ show edit update destroy ]

  # GET /unit_preferences or /unit_preferences.json
  def index
    @unit_preferences = UnitPreference.all
    authorize @unit_preferences
  end

  # GET /unit_preferences/1 or /unit_preferences/1.json
  def show
  end

  # GET /unit_preferences/new
  def new
    @unit_preference = UnitPreference.new
    authorize @unit_preference
    @units = Unit.all
  end

  # GET /unit_preferences/1/edit
  def edit
    @units = Unit.all
  end

  # POST /unit_preferences or /unit_preferences.json
  def create
    @unit_preference = UnitPreference.new(unit_preference_params)
    authorize @unit_preference
    respond_to do |format|
      if @unit_preference.save
        format.html { redirect_to unit_preference_url(@unit_preference), notice: "Unit preference was successfully created." }
        format.json { render :show, status: :created, location: @unit_preference }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @unit_preference.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /unit_preferences/1 or /unit_preferences/1.json
  def update
    respond_to do |format|
      if @unit_preference.update(unit_preference_params)
        format.html { redirect_to unit_preference_url(@unit_preference), notice: "Unit preference was successfully updated." }
        format.json { render :show, status: :ok, location: @unit_preference }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @unit_preference.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /unit_preferences/1 or /unit_preferences/1.json
  def destroy
    @unit_preference.destroy

    respond_to do |format|
      format.html { redirect_to unit_preferences_url, notice: "Unit preference was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit_preference
      @unit_preference = UnitPreference.find(params[:id])
      authorize @unit_preference
    end

    # Only allow a list of trusted parameters through.
    def unit_preference_params
      params.require(:unit_preference).permit(:name, :description, :value, :unit_id)
    end
end
