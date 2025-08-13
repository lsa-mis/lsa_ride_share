import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'car', 'driver']
  
  connect () {
    console.log("connect vehiclereportfilters")
  }

  resetAndSearch() {
    this.carTarget.value = ""
    this.driverTarget.value = ""
    Turbo.navigator.submitForm(this.formTarget)
  }
  search() {
    Turbo.navigator.submitForm(this.formTarget)
  }
}
