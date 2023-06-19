import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['form','unit',
    'day_start', 'number', 'start_time', 'end_time', 'selected_time_error', 'car', 'car_field']

  connect() {
    console.log("connect - edit reservation")
  }

  availableCars(){
    console.log("available")
    let unit_id = this.unitTarget.value
    let day_start = this.day_startTarget.value
    let number = this.numberTarget.value
    let start_time = this.start_timeTarget.value
    let end_time = this.end_timeTarget.value
    let start_time_format = new Date(start_time)
    let end_time_format = new Date(end_time)
    let diff_time = parseInt(end_time_format - start_time_format)/60000;
    console.log(unit_id)
    console.log(day_start)
    console.log(number)
    console.log(start_time)
    console.log(end_time)



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

    get(`/reservations/get_available_cars/${unit_id}/${day_start}/${number}/${start_time}/${end_time}`, {
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
    let required_fields_error = document.getElementById('required_fields')
    let car_field_error = document.getElementById('car_field')
    let submitForm = true

    if (car == "") {
      car_field_error.innerHTML = "Please select a car"
      required_fields_error.innerHTML = ''
      submitForm = false
    } else {
      required_fields_error.innerHTML = ''
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
    else {
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
