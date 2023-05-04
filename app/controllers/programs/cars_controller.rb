class Programs::CarsController < CarsController
  before_action :set_car_program

  private

    def set_car_program
      @car_program = Program.find(params[:program_id])
    end
end
