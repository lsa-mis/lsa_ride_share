class Reservations::VehicleReportsController < VehicleReportsController
  before_action :set_reservation

  private

  def set_reservation
      @reservation = Reservation.find(params[:reservation_id])
  end

end