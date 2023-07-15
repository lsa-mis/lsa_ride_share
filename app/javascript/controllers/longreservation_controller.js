import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['unit',
    'day_start', 'day_end', 'number', 'start_time', 'end_time', 'selected_time_error', 'car', 'car_field']

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

  // submitForm(event) {
  //   let term = this.termTarget.value
  //   let program = this.programTarget.value
  //   let site = this.siteTarget.value
  //   let car = this.carTarget.value

  //   let start_time = this.start_timeTarget.value
  //   let end_time = this.end_timeTarget.value
  //   let start_time_format = new Date(start_time)
  //   let end_time_format = new Date(end_time)
  //   let diff_time = parseInt(end_time_format - start_time_format)/60000;
    
  //   let time_field_error = document.getElementById('time_field')
  //   let required_fields_error = document.getElementById('required_fields')
  //   let car_field_error = document.getElementById('car_field')
  //   let submitForm = true

  //   if(term == "" || program == "" || site == "") {
  //     required_fields_error.innerHTML = "Please select required data"
  //     car_field_error.innerHTML = ''
  //     submitForm = false
  //   } else if (car == "") {
  //     car_field_error.innerHTML = "Please select a car"
  //     required_fields_error.innerHTML = ''
  //     submitForm = false
  //   } else {
  //     required_fields_error.innerHTML = ''
  //     car_field_error.innerHTML = ''
  //   }

  //   if (diff_time < 31) {
  //     time_field_error.innerHTML = "End time is too close to the start time"
  //     submitForm = false
  //   } else {
  //     time_field_error.innerHTML = ''
  //   }

  //   if(submitForm == false) {
  //     event.preventDefault()
  //   }
  // }

}
