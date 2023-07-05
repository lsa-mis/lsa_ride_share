import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'gas_start',
          'mileage_error', 'mileage_start', 'mileage_end']
  connect() {
    console.log("connect - vehicle report")
  }

  submitForm(event) {
    
    var gas_start = this.gas_startTarget.value

    var mileage_start = this.mileage_startTarget.value
    var mileage_end = this.mileage_endTarget.value

    var mileage_error_place = document.getElementById('mileage_show_error')
    var gas_error_place = document.getElementById('gas_error')
  
    var submitForm = true

    if(gas_start == null || gas_start == "") {
      gas_error_place.innerHTML = "Gas (departure) must be selected."
      submitForm = false
    }
    else {
      gas_error_place.innerHTML = ''
    }

    if (mileage_start < 0 || mileage_end < 0) {
      mileage_error_place.innerHTML = "Mileage needs to be a postive value. Please enter a valid value."
      submitForm = false
    }
    else if(mileage_end < mileage_start) {
      mileage_error_place.innerHTML = "End mileage should be higher than start mileage. Please enter a valid value."
      submitForm = false
    } else {
      mileage_error_place.innerHTML = ''
    }   
   
    if(submitForm == false) {
      event.preventDefault()
    }
    else {
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
