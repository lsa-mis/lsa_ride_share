import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'number_of_non_uofm_passengers', 'non_uofm_passengers']
  connect() {
    console.log("connect - passenger")
  }

  submitForm(event) {
    var non_uofm_number = Number(this.number_of_non_uofm_passengersTarget.value)
    console.log(non_uofm_number)
    var non_uofm_passengers = this.non_uofm_passengersTarget.value
    console.log(non_uofm_passengers)
    var error_place = document.getElementById('error_place')

    if (non_uofm_number > 0 && non_uofm_passengers == ''){
      error_place.innerHTML = "The empty passengers list doesn't match the non-zero number"
      event.preventDefault()
    } else if (non_uofm_number == 0 && non_uofm_passengers != '' ) {
      error_place.innerHTML = "Zero number doesn't match the non-empty passengers list"
      event.preventDefault()
    } 
  }

}
