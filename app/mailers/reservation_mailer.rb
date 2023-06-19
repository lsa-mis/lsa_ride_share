class ReservationMailer < ApplicationMailer
  # before_action :set_reservation
  # before_action :set_recipient

  def car_reservation_created
    @reservation = params[:reservation]
    @reserved_by_name = User.find(@reservation.reserved_by).display_name
    @recipient = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    mail(to: @recipient, subject: "New reservation for program: #{@reservation.program.display_name}" )
  end

end