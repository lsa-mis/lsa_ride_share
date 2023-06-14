import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'number_of_people_on_trip', 'number_of_passengers',
    'driver', 'driver_phone',
    'backup_driver', 'backup_driver_phone']
  connect() {
    console.log("connect - driver")
  }

  submitForm(event) {
    var driver = this.driverTarget.value
    var driver_phone = this.driver_phoneTarget.value
    var number = this.number_of_people_on_tripTarget.value - this.number_of_passengersTarget.value  - 1
    var driver_error_place = document.getElementById('driver_error')
    var backup_driver_error_place = document.getElementById('backup_driver_error')
    var submitForm = true

    if (driver == "" && driver_phone == "") {
      driver_error_place.innerHTML = "Please select a driver and enter driver's phone"
      submitForm = false
    } else if (driver == "") {
      driver_error_place.innerHTML = 'Please select a driver'
      submitForm = false
    } else if (driver_phone == "") {
      driver_error_place.innerHTML = "Please enter driver's phone"
      submitForm = false
    } else {
      driver_error_place.innerHTML = ''
    }

    if (this.number_of_people_on_tripTarget.value > 1) { 
      var backup_driver = this.backup_driverTarget.value
      var backup_driver_phone = this.backup_driver_phoneTarget.value

      if (backup_driver != "" && number == 0) {
        backup_driver_error_place.innerHTML = 'Please remove one passenger then add a backup driver'
        submitForm = false
      } else if (driver != '' && driver == backup_driver) {
        backup_driver_error_place.innerHTML = 'Driver and backup driver should be different'
        submitForm = false
      } else if (backup_driver != "" && backup_driver_phone == "") {
        backup_driver_error_place.innerHTML = "Please enter backup driver's phone"
        submitForm = false
      } else {
        backup_driver_error_place.innerHTML = ''
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
