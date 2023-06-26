import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'gas_error', 'gas_start', 'gas_end',
          'mileage_error', 'mileage_start', 'mileage_end']
  connect() {
    console.log("connect - vehicle report")
  }

  submitForm(event) {
    var gas_start = this.gas_startTarget.value
    var gas_end = this.gas_endTarget.value
    var mileage_start = this.mileage_startTarget.value
    var mileage_end = this.mileage_endTarget.value
  
    gas_start = Number(gas_start)
    gas_end = Number(gas_end)
    var submitForm = true

    if(gas_start > 100 || gas_start < 0 || gas_end > 100 || gas_end < 0) {
      this.gas_errorTarget.classList.add("fields--display")
      this.gas_errorTarget.classList.remove("fields--hide")
      submitForm = false
    } else {
      this.gas_errorTarget.classList.remove("fields--display")
      this.gas_errorTarget.classList.add("fields--hide")
    }

    if (mileage_start && mileage_end) {
      if(Number(mileage_end) < Number(mileage_start)) {
        this.mileage_errorTarget.classList.add("fields--display")
        this.mileage_errorTarget.classList.remove("fields--hide")
        submitForm = false
      } else {
        this.mileage_errorTarget.classList.remove("fields--display")
        this.mileage_errorTarget.classList.add("fields--hide")
      }
    }

    if(submitForm == false) {
      event.preventDefault()
    }
    else {
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
