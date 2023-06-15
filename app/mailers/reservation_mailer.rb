class ReservationMailer < ApplicationMailer
  def car_reservation_created
    @reservation = params[:reservation]
    @reserved_by_name = User.find(@reservation.reserved_by).display_name
    mail(to: @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value, subject: "New reservation for program: #{@reservation.program.title}" )
  end
end