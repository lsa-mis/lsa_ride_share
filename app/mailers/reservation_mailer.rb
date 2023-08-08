class ReservationMailer < ApplicationMailer
  before_action :set_reservation, only: [:car_reservation_created, :car_reservation_approved, :car_reservation_confirmation, :car_reservation_updated]
  before_action :set_driver_name, only: [:car_reservation_created, :car_reservation_approved, :car_reservation_confirmation, :car_reservation_updated]
  before_action :set_passengers, only: [:car_reservation_created, :car_reservation_approved, :car_reservation_confirmation, :car_reservation_updated]

  def car_reservation_created(user)
    @recipient = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    mail(to: @recipient, subject: "New reservation for program: #{@reservation.program.display_name}" )
    EmailLog.create(sent_from_model: "Reservation", record_id: @reservation.id, email_type: "car_reservation_created",
      sent_to: @recipient, sent_by: user.id, sent_at: DateTime.now)
  end

  def car_reservation_confirmation(user)
    recipients = []
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    @recipients = recipients.join(", ")
    mail(to: @recipients, subject: "Reservation confirmation for program: #{@reservation.program.display_name}" )
    EmailLog.create(sent_from_model: "Reservation", record_id: @reservation.id, email_type: "car_reservation_confirmation",
      sent_to: @recipients, sent_by: user.id, sent_at: DateTime.now)
  end

  def car_reservation_approved(user)
    recipients = []
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    @recipients = recipients.join(", ")
    mail(to: @recipients, subject: "Reservation approved for program: #{@reservation.program.display_name}" )
    EmailLog.create(sent_from_model: "Reservation", record_id: @reservation.id, email_type: "car_reservation_approved",
      sent_to: @recipients, sent_by: user.id, sent_at: DateTime.now)
  end

  def car_reservation_cancel_admin(cancel_reservation, cancel_passengers, cancel_emails, user)
    @passengers = cancel_passengers
    @start_time = show_date_time(cancel_reservation.start_time)
    @end_time = show_date_time(cancel_reservation.end_time)
    if cancel_reservation.driver.present?
      @driver_name = show_driver(cancel_reservation)
    else
      @driver_name = "Not Selected"
    end
    if cancel_reservation.backup_driver.present?
      @backup_driver_name = show_backup_driver(cancel_reservation)
    else
      @backup_driver_name = "Not Selected"
    end
    @admin_email = cancel_reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    @reservation = cancel_reservation
    mail(to: @admin_email, subject: "Reservation canceled for program: #{@reservation.program.display_name}" )
    EmailLog.create(sent_from_model: "Reservation", record_id: @reservation.id, email_type: "car_reservation_cancel_admin",
      sent_to: @admin_email, sent_by: user, sent_at: DateTime.now)
  end

  def car_reservation_cancel_student(cancel_reservation, cancel_passengers, cancel_emails, user)
    @contact_phone = cancel_reservation.program.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
    @unit_email = cancel_reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    @passengers = cancel_passengers
    @start_time = show_date_time(cancel_reservation.start_time)
    @end_time = show_date_time(cancel_reservation.end_time)
    if cancel_reservation.driver.present?
      @driver_name = show_driver(cancel_reservation)
    else
      @driver_name = "Not Selected"
    end
    if cancel_reservation.backup_driver.present?
      @backup_driver_name = show_backup_driver(cancel_reservation)
    else
      @backup_driver_name = "Not Selected"
    end
    recipients = []
    recipients << email_address(cancel_reservation.driver) if cancel_reservation.driver.present?
    recipients << email_address(cancel_reservation.backup_driver) if cancel_reservation.backup_driver.present?
    recipients << cancel_emails if cancel_emails.present?
    @recipients = recipients.join(", ")
    @reservation = cancel_reservation
    mail(to: @recipients, subject: "Reservation canceled for program: #{@reservation.program.display_name}" )
    EmailLog.create(sent_from_model: "Reservation", record_id: @reservation.id, email_type: "car_reservation_cancel_student",
      sent_to: @recipients, sent_by: user, sent_at: DateTime.now)
  end

  def car_reservation_updated(user)
    recipients = []
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    @recipients = recipients.join(", ")
    mail(to: @recipients, subject: "Reservation updated for program: #{@reservation.program.display_name}" )
    EmailLog.create(sent_from_model: "Reservation", record_id: @reservation.id, email_type: "car_reservation_updated",
      sent_to: @recipients, sent_by: user.id, sent_at: DateTime.now)
  end

  private 

  def set_reservation
    @reservation = params[:reservation]
    @start_time = show_date_time(@reservation.start_time)
    @end_time = show_date_time(@reservation.end_time)
    @contact_phone = @reservation.program.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
    @unit_email = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
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
    if @reservation.program.non_uofm_passengers && @reservation.non_uofm_passengers.present? 
      @non_uofm_passengers = @reservation.non_uofm_passengers
    end
  end

end
