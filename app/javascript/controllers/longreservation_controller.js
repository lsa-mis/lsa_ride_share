import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['unit',
    'day_start', 'day_end', 'number', 'start_time', 'end_time', 'selected_time_error', 'car', 'car_selection', 'car_field']

  connect() {
    console.log("connect - long reservation")
  }

  availableCars(){
    console.log("long reservation - available cars")
    let unit_id = this.unitTarget.value
    let day_start = this.day_startTarget.value
    let day_end = this.day_endTarget.value
    let number = this.numberTarget.value
    let start_time = this.start_timeTarget.value
    let end_time = this.end_timeTarget.value
    let start_time_format = new Date(start_time)
    let end_time_format = new Date(end_time)
    let diff_time = parseInt(end_time_format - start_time_format)/60000;

    let time_field_error = document.getElementById('time_field')
    let car_field_error = document.getElementById('car_field')

    if (diff_time > 0 && diff_time < 31) {
      time_field_error.innerHTML = 'End time is too close to start time'
      car_field_error.innerHTML = ''
    } else if (start_time_format > end_time_format) {
      time_field_error.innerHTML = 'Start time should occur before end time'
      car_field_error.innerHTML = ''
    }else {
      time_field_error.innerHTML = ''
    }

    get(`/reservations/get_available_cars_long/${unit_id}/${day_start}/${day_end}/${number}/`, {
      responseKind: "turbo-stream"
    })

  }

  hideCarSelection() {
    let unit_id = this.unitTarget.value
    let day_start = this.day_startTarget.value
    var hide = document.getElementById("no_car").checked
    console.log(hide)
    if (hide) {
      this.carTarget.value = ""
      this.car_selectionTarget.classList.add("fields--hide")
      this.car_selectionTarget.classList.remove("fields--display")
    }
    else {
      this.car_selectionTarget.classList.add("fields--display")
      this.car_selectionTarget.classList.remove("fields--hide")
    }

  }

}
