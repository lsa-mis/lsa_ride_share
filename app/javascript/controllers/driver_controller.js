import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['form',
    'driver', 'driver_phone', 'driver_error',
    'backup_driver', 'backup_driver_phone', 'backup_driver_error', 'equal_drivers_error']
  connect() {
    console.log("connect - driver")
  }

  submitForm(event) {
    var driver = this.driverTarget.value
    var driver_phone = this.driver_phoneTarget.value
    var backup_driver = this.backup_driverTarget.value
    var backup_driver_phone = this.backup_driver_phoneTarget.value

    if(driver == "" || driver_phone == "") {
      this.driver_errorTarget.classList.add("fields--display")
      this.driver_errorTarget.classList.remove("fields--hide")
      this.equal_drivers_errorTarget.classList.remove("fields--display")
      this.equal_drivers_errorTarget.classList.add("fields--hide")
      this.backup_driver_errorTarget.classList.remove("fields--display")
      this.backup_driver_errorTarget.classList.add("fields--hide")
      event.preventDefault()
    } else if (driver != '' && driver == backup_driver) {
      console.log("hellllll")
      this.equal_drivers_errorTarget.classList.add("fields--display")
      this.equal_drivers_errorTarget.classList.remove("fields--hide")
      this.backup_driver_errorTarget.classList.remove("fields--display")
      this.backup_driver_errorTarget.classList.add("fields--hide")
      this.driver_errorTarget.classList.remove("fields--display")
      this.driver_errorTarget.classList.add("fields--hide")
      event.preventDefault()
    } else if (backup_driver != "" && backup_driver_phone == "") {
      this.backup_driver_errorTarget.classList.add("fields--display")
      this.backup_driver_errorTarget.classList.remove("fields--hide")
      this.driver_errorTarget.classList.remove("fields--display")
      this.driver_errorTarget.classList.add("fields--hide")
      this.equal_drivers_errorTarget.classList.remove("fields--display")
      this.equal_drivers_errorTarget.classList.add("fields--hide")
      event.preventDefault()
    }
    else{
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
