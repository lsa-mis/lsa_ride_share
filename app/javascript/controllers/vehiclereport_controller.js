import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'gas_start',
          'mileage_error', 'mileage_start', 'mileage_end',
          'parking_return', 'parking_other_div', 'parking_other']
  connect() {
    console.log("connect - vehicle report")
  }

  otherParking(){
    var parking_return = this.parking_returnTarget.value.toLowerCase()
    var parking_other_error_place = document.getElementById('parking_other_error_place')
    if (parking_return == 'other') {
      this.parking_otherTarget.value = ""
      this.parking_other_divTarget.classList.remove("fields--hide")
      this.parking_other_divTarget.classList.add("fields--display")
    }
    else {
      this.parking_otherTarget.value = ""
      parking_other_error_place.innerHTML = ''
      this.parking_other_divTarget.classList.add("fields--hide")
      this.parking_other_divTarget.classList.remove("fields--display")
    }
  }

  submitForm(event) {
    var gas_start = this.gas_startTarget.value
    var mileage_start = Number(this.mileage_startTarget.value)
    var mileage_end = Number(this.mileage_endTarget.value)
    var mileage_error_place = document.getElementById('mileage_show_error')
    var gas_error_place = document.getElementById('gas_error')
    var error_scroll_place = document.getElementById('error_scroll_place')
    var parking_return = this.parking_returnTarget.value.toLowerCase()
    var parking_other = this.parking_otherTarget.value
    var parking_other_error_place = document.getElementById('parking_other_error_place')
  
    var submitForm = true

    if(gas_start == null || gas_start == "") {
      gas_error_place.innerHTML = "Fuel (departure) must be selected."
      error_scroll_place.scrollIntoView()
      submitForm = false
    }
    else {
      gas_error_place.innerHTML = ''
    }

    mileage_error_place.innerHTML = ''
    if (mileage_start < 0 || mileage_end < 0) {
      mileage_error_place.innerHTML = "Mileage needs to be a postive value. Please enter a valid value."
      error_scroll_place.scrollIntoView()
      submitForm = false
    }
    if(mileage_end > 0 && mileage_end < mileage_start) {
      mileage_error_place.innerHTML = "End mileage should be higher than start mileage. Please enter a valid value."
      error_scroll_place.scrollIntoView()
      submitForm = false
    }

    parking_other_error_place.innerHTML = ''
    if(parking_return == "other" && parking_other == "") {
      parking_other_error_place.innerHTML = "Please enter the other parking spot"
      submitForm = false
    }
    if (parking_return != "other"){
      this.parking_otherTarget.value = ""
    }

    if(submitForm == false) {
      event.preventDefault()
    }
    // else {
    //   Turbo.navigator.submitForm(this.formTarget)
    // }
  }

}
