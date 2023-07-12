class Reservations::PassengersController < ApplicationController
  before_action :set_reservation

  def add_passengers
    @passengers = @reservation.passengers
    @students = @reservation.program.students - @passengers
    @students.delete(@reservation.driver)
    @students.delete(@reservation.backup_driver)
    authorize([@reservation, @passengers]) 
  end

  def add_passenger
    authorize([@reservation, Student])
    if params[:reservation][:student_id].present?
      @reservation.passengers << Student.find(params[:reservation][:student_id])
      redirect_to add_passengers_path(@reservation, :edit => params[:reservation][:edit])
    end
  end

  def remove_passenger
    authorize([@reservation, Student])
    @reservation.passengers.delete(Student.find(params[:student_id]))
    redirect_to add_passengers_path(@reservation, :edit => params[:edit])
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:reservation_id])
  end
end
