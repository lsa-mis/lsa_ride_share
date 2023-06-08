import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'number_of_people_on_trip', 'number_of_passengers',
    'driver', 'driver_phone', 'driver_error',
    'backup_driver', 'backup_driver_phone']
  connect() {
    console.log("connect - driver")
  }

  submitForm(event) {
    var driver = this.driverTarget.value
    var driver_phone = this.driver_phoneTarget.value
    var backup_driver = this.backup_driverTarget.value
    var backup_driver_phone = this.backup_driver_phoneTarget.value
    var number = this.number_of_people_on_tripTarget.value - this.number_of_passengersTarget.value  - 1
    var error_place = document.getElementById('backup_driver_error');

    if(driver == "" || driver_phone == "") {
      this.driver_errorTarget.classList.add("fields--display")
      this.driver_errorTarget.classList.remove("fields--hide")
      error_place.innerHTML = ''
      event.preventDefault()
    } else if (backup_driver != "" && number == 0) {
      error_place.innerHTML = 'Please remove one passenger then add a backup driver';
      this.driver_errorTarget.classList.remove("fields--display")
      this.driver_errorTarget.classList.add("fields--hide")
      event.preventDefault()
    } else if (driver != '' && driver == backup_driver) {
      error_place.innerHTML = 'Driver and backup driver should be different';
      this.driver_errorTarget.classList.remove("fields--display")
      this.driver_errorTarget.classList.add("fields--hide")
      event.preventDefault()
    } else if (backup_driver != "" && backup_driver_phone == "") {
      error_place.innerHTML = "Please enter backup driver's phone";
      this.driver_errorTarget.classList.remove("fields--display")
      this.driver_errorTarget.classList.add("fields--hide")
      event.preventDefault()
    }
    else{
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
