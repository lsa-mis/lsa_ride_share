import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'gas_error', 'gas_start',
    'gas_end']
  connect() {
    console.log("connect - vehicle report")
  }

  submitForm(event) {
    var gas_start = this.gas_startTarget.value
    var gas_end = this.gas_endTarget.value

    gas_start = Number(gas_start)
    gas_end = Number(gas_end)

    console.log(gas_start)
    console.log(gas_end)

    if(gas_start > 100 || gas_start < 0 || gas_end > 100 || gas_end < 0) {
      this.gas_errorTarget.classList.add("fields--display")
      this.gas_errorTarget.classList.remove("fields--hide")

      event.preventDefault()
    }
    else{
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
