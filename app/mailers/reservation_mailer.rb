class ReservationMailer < ApplicationMailer
  before_action :set_reservation, except: %i[ to_selected_reservations_copy_to_admin import_reservations_report ]
  before_action :set_driver_name, except: %i[ to_selected_reservations_copy_to_admin import_reservations_report ]
  before_action :set_passengers, except: %i[ to_selected_reservations_copy_to_admin import_reservations_report ]
  include MailerHelper

  def car_reservation_created(conflict_days_message = " ")
    @recipients = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    set_subject_email_type_recurring_rule("created")
    @conflict_days_message = conflict_days_message
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: "all")
  end

  def car_reservation_confirmation(conflict_days_message = "")
    create_recipients_list
    set_subject_email_type_recurring_rule("confirmation")
    @conflict_days_message = conflict_days_message
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: "all")
  end

  def car_reservation_approved
    create_recipients_list(reserved_by_flag: false)
    @email_type = "approved"
    @unit_email_message = get_unit_email_message(@reservation)
    mail(to: @recipients, subject: "Reservation approved for program: #{@reservation.program.display_name}" )
    create_email_log_records
  end

  def car_reservation_cancel_admin(cancel_passengers, cancel_emails, reason_for_cancellation = "", cancel_message = "", cancel_type = "")
    @passengers = cancel_passengers
    @reason_for_cancellation = reason_for_cancellation
    user = params[:user]
    set_subject_email_type_recurring_rule("cancel_admin")
    if params[:recurring]
      @cancel_message = cancel_message + " scheduled '" + @recurring_rule + "' were canceled on " + show_date_time(DateTime.now) + " by " + show_user_name_by_id(user.id) + " for the following reason: "
    else
      @cancel_message = "The reservation was canceled on " + show_date_time(DateTime.now) + " by " + show_user_name_by_id(user.id) + " for the following reason: "
    end
    @recipients = @unit_email
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: cancel_type)
  end

  def car_reservation_cancel_driver(cancel_passengers, cancel_emails, reason_for_cancellation = "", cancel_message = "", cancel_type = "")
    @passengers = cancel_passengers
    @reason_for_cancellation = reason_for_cancellation
    user = params[:user]
    create_recipients_list(cancel_emails: cancel_emails)
    set_subject_email_type_recurring_rule("cancel_driver")
    if params[:recurring]
      @cancel_message = cancel_message + " scheduled '" + @recurring_rule + "' were canceled on " + show_date_time(DateTime.now) + " by " + show_user_name_by_id(user.id) + " for the following reason: "
    else
      @cancel_message = "Your reservation was canceled on " + show_date_time(DateTime.now) + " by " + show_user_name_by_id(user.id) + " for the following reason: "
    end
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: cancel_type)
  end

  def car_reservation_updated(admin: false)
    # admin == false - don't sent email to admin
    # admin == true - send email to admin
    create_recipients_list(admin_flag: admin)
    set_subject_email_type_recurring_rule("updated")
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: "following")
  end

  def car_reservation_drivers_edited(drivers_emails)
    @unit_email_message = get_unit_email_message(@reservation)
    recipients = drivers_emails
    recipients << User.find(@reservation.reserved_by).principal_name.presence
    # recipients << @passengers_emails if @passengers_emails.present?
    recipients << @unit_email
    @recipients = recipients.uniq.join(", ")
    set_subject_email_type_recurring_rule("drivers_edited")
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: "following")
  end

  def car_reservation_remove_passenger(passenger)
    @name = passenger.name
    @recipients = email_address(passenger)
    set_subject_email_type_recurring_rule("passenger_removed")
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: "following")
  end

  def car_reservation_update_passengers
    create_recipients_list(admin_flag: true)
    set_subject_email_type_recurring_rule("passengers_updated")
    mail(to: @recipients, subject: @subject)
    create_email_log_records(recurring_type: "following")
  end

  def one_hour_reminder
    recipients = []
    if @reservation.driver.present?
      if subscribed?(mailer: "one_hour_reminder", driver: @reservation.driver)
        recipients << email_address(@reservation.driver)
      end
    end
    if @reservation.driver_manager.present? 
      if subscribed?(mailer: "one_hour_reminder", driver: @reservation.driver_manager)
        recipients << email_address(@reservation.driver_manager)
      end
    end
    if @reservation.backup_driver.present? 
      if subscribed?(mailer: "one_hour_reminder", driver: @reservation.backup_driver)
        recipients << email_address(@reservation.backup_driver)
      end
    end
    if recipients.present?
      @recipients = recipients.uniq.join(", ")
      set_subject_email_type_recurring_rule("one_hour_reminder")
      mail(to: @recipients, subject: @subject)
      create_email_log_records(user_id: User.find_by(uniqname: "cron_job").id)
    end
  end

  def vehicle_report_reminder
    recipients = []
    if @reservation.driver.present? 
      if subscribed?(mailer: "vehicle_report_reminder", driver: @reservation.driver)
        recipients << email_address(@reservation.driver)
      end
    end
    if @reservation.driver_manager.present? 
      if subscribed?(mailer: "vehicle_report_reminder", driver: @reservation.driver_manager)
        recipients << email_address(@reservation.driver_manager)
      end
    end
    if @reservation.backup_driver.present? 
      if subscribed?(mailer: "vehicle_report_reminder", driver: @reservation.backup_driver)
        recipients << email_address(@reservation.backup_driver)
      end
    end
    if recipients.present?
      @recipients = recipients.uniq.join(", ")
      set_subject_email_type_recurring_rule("vehicle_report_reminder")
      mail(to: @recipients, subject: @subject)
      create_email_log_records(user_id: User.find_by(uniqname: "cron_job").id)
    end
  end

  def to_selected_reservations
    subject = params[:subject]
    @message = params[:message]
    create_recipients_list()
    @email_type = "admin"
    mail(to: @recipients, subject: subject)
    create_email_log_records
  end

  def to_selected_reservations_copy_to_admin(selected_reservations)
    @selected_reservations = selected_reservations
    reservation = Reservation.find(@selected_reservations.first)
    @day = reservation.start_time.to_date.strftime("%A, %d %B %Y") 
    subject = "Admin copy: " + params[:subject]
    @message = params[:message]
    user = params[:user]
    unit_email = reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    mail(to: unit_email, subject: subject)
  end

  def import_reservations_report
    @import_result = params[:import_result]
    unit = Unit.find(params[:unit_id])
    user = params[:user]
    unit_email = unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
    mail(to: unit_email, subject: 'Reservation Import Report for unit: ' + unit.name)
  end
  private 

  def set_reservation
    @reservation = params[:reservation]
    @start_time = show_date_time(@reservation.start_time + 15.minute)
    @end_time = show_date_time(@reservation.end_time - 15.minute)
    @contact_phone = @reservation.program.unit.unit_preferences.find_by(name: "contact_phone").value.presence || ""
    @unit_email = @reservation.program.unit.unit_preferences.find_by(name: "notification_email").value.presence || "lsa-rideshare-admins@umich.edu"
  end

  def set_driver_name
    if @reservation.driver.present? || @reservation.driver_manager.present?
      @driver_name = show_driver(@reservation)
    else
      @driver_name = "Not Selected"
    end
      @backup_driver_name = show_backup_driver(@reservation)

  end

  def set_passengers
    @passengers = []
    @passengers_emails =[]
    if @reservation.passengers.present? || @reservation.passengers_managers.present?
      @reservation.passengers.each do |p|
        @passengers << p.name
        @passengers_emails << email_address(p)
      end
      @reservation.passengers_managers.each do |p|
        @passengers << p.name + show_manager(@reservation.program, p.uniqname)
        @passengers_emails << email_address(p)
      end
    else
      @passengers = ["No passengers"]
    end
    if @reservation.program.non_uofm_passengers && @reservation.non_uofm_passengers.present? 
      @non_uofm_passengers = @reservation.non_uofm_passengers
    end
  end

  def get_unit_email_message(reservation)
    if UnitPreference.find_by(name: "unit_email_message", unit_id: reservation.program.unit_id).present?
      unit_email_message = UnitPreference.find_by(name: "unit_email_message", unit_id: reservation.program.unit_id).value
    else
      unit_email_message = ""
    end
    return unit_email_message
  end

  def create_recipients_list(reserved_by_flag: true, cancel_emails: nil, admin_flag: false)
    recipients = []
    recipients << User.find(@reservation.reserved_by).principal_name.presence unless reserved_by_flag
    recipients << email_address(@reservation.driver) if @reservation.driver.present?
    recipients << email_address(@reservation.driver_manager) if @reservation.driver_manager.present?
    recipients << email_address(@reservation.backup_driver) if @reservation.backup_driver.present?
    recipients << @passengers_emails if @passengers_emails.present?
    recipients << cancel_emails if cancel_emails.present?
    recipients << @unit_email if admin_flag
    unless recipients.present?
      recipients << @unit_email
    end
    @recipients = recipients.uniq.join(", ")
  end

  def set_subject_email_type_recurring_rule(type)
    case type
    when "cancel_admin", "cancel_driver"
      subject = "canceled"
    when "drivers_edited"
      subject = "- drivers changed"
    when "passenger_removed"
      subject = "- removed from the passengers list"
    when "passengers_updated"
      subject = "- passengers list updated"
    when "one_hour_reminder"
      subject = "- reminder"
    when "vehicle_report_reminder"
      subject = "- vehicle report reminder"
    else 
      subject = type
    end
    if params[:recurring]
      @subject =  "Recurring Reservation " + subject + " for program: #{@reservation.program.display_name_with_title}"
      @email_type = "recurring_" + type
      @recurring_reservation = RecurringReservation.new(@reservation)
      @recurring_rule = @recurring_reservation.first_reservation.rule.to_s
    else
      @subject = "Reservation " + subject + " for program: #{@reservation.program.display_name_with_title}"
      @email_type = type
    end
  end

  def create_email_log_records(recurring_type: "", user_id: params[:user].id)
    if params[:recurring]
      recurring_reservation = RecurringReservation.new(@reservation)
      case recurring_type
      when "one"
        all_reservations = Array(@reservation.id)
      when "following"
        all_reservations = recurring_reservation.get_following
      when "all"
        all_reservations = recurring_reservation.get_all_reservations
      else 
        all_reservations = Array(@reservation.id)
      end
    else
      all_reservations = Array(@reservation.id)
    end
    all_reservations.each do |id|
      EmailLog.create(sent_from_model: "Reservation", record_id: id, email_type: @email_type,
        sent_to: @recipients, sent_by: user_id, sent_at: DateTime.now)
    end
  end
end
