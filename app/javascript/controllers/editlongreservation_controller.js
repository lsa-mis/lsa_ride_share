import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['form','unit',
    'day_start', 'day_end', 'number', 'start_time', 'end_time', 'selected_time_error', 'car', 'car_field']

  connect() {
    console.log("connect - edit reservation")
  }

  changeStartEndDay(){
    console.log("here)")
    let unit_id = this.unitTarget.value
    let day_start = this.day_startTarget.value
    let day_end = this.day_endTarget.value
    let start_time = this.start_timeTarget.value
    let end_time = this.end_timeTarget.value

    get(`/reservations/change_start_end_day/${unit_id}/${day_start}/${day_end}/${start_time}/${end_time}`, {
      responseKind: "turbo-stream"
    })
  }

  submitForm(event) {
    let car = this.carTarget.value

    let start_time = this.start_timeTarget.value
    let end_time = this.end_timeTarget.value
    let start_time_format = new Date(start_time)
    let end_time_format = new Date(end_time)
    let diff_time = parseInt(end_time_format - start_time_format)/60000;
    
    let time_field_error = document.getElementById('time_field')
    let car_field_error = document.getElementById('car_field')
    let submitForm = true

    if (car == "") {
      car_field_error.innerHTML = "Please select a car"
      submitForm = false
    } else {
      car_field_error.innerHTML = ''
    }

    if (diff_time < 31) {
      time_field_error.innerHTML = "End time is too close to the start time"
      submitForm = false
    } else {
      time_field_error.innerHTML = ''
    }

    if(submitForm == false) {
      event.preventDefault()
    }
  }

}
