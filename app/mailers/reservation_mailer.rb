class ReservationMailer < ApplicationMailer
  before_action :set_reservation, only: [:car_reservation_created, :car_reservation_approved]
  before_action :set_driver_name, only: [:car_reservation_created, :car_reservation_approved]
  before_action :set_passengers, only: [:car_reservation_created, :car_reservation_approved]

  def car_reservation_created
    @recipient = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    mail(to: @recipient, subject: "New reservation for program: #{@reservation.program.display_name}" )
  end

  def car_reservation_approved
    recipients = []
    # recipients << User.find(@reservation.reserved_by).principal_name.presence || "lsa-rideshare-admins@umich.edu"
    recipients << email_address(@reservation.driver)
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    @recipients = recipients.join(", ")
    mail(to: @recipients, subject: "Reservation approved for program: #{@reservation.program.display_name}" )
  end

  private 

  def set_reservation
    @reservation = params[:reservation]
    @start_time = show_date_time(@reservation.start_time)
    @end_time = show_date_time(@reservation.end_time) 
  end

  def set_driver_name
    if @reservation.driver.present?
      @driver_name = show_driver(@reservation)
    else
      @driver_name = "Not Selected"
    end
    if @reservation.backup_driver.present?
      @backup_driver_name = show_backup_driver(@reservation)
    else
      @backup_driver_name = "Not Selected"
    end
  end

  def set_passengers
    @passengers = []
    @passengers_emails =[]
    if @reservation.passengers.present?
      @reservation.passengers.each do |p|
        @passengers << p.name
        @passengers_emails << email_address(p)
      end
    else
      @passengers = ["No passengers"]
    end
  end

end