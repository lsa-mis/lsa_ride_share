import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'car', 'driverStudent', 'driverManager']

  connect () {
    console.log("connect vehiclereportfilters")
  }

  resetCarDriversAndSearch() {
    this.carTarget.value = ""
    if (this.hasDriverStudentTarget) {
      this.driverStudentTarget.value = ""
    }
    if (this.hasDriverManagerTarget) {
      this.driverManagerTarget.value = ""
    }
    Turbo.navigator.submitForm(this.formTarget)
  }

  resetDriversAndSearch() {
    if (this.hasDriverStudentTarget) {
      this.driverStudentTarget.value = ""
    }
    if (this.hasDriverManagerTarget) {
      this.driverManagerTarget.value = ""
    }
    Turbo.navigator.submitForm(this.formTarget)
  }
  resetCarDriverManagerAndSearch() {
    this.carTarget.value = ""
    if (this.hasDriverManagerTarget) {
      this.driverManagerTarget.value = ""
    }
    Turbo.navigator.submitForm(this.formTarget)
  }

  resetCarDriverStudentAndSearch() {
    this.carTarget.value = ""
    if (this.hasDriverStudentTarget) {
      this.driverStudentTarget.value = ""
    }
    Turbo.navigator.submitForm(this.formTarget)
  }

}
