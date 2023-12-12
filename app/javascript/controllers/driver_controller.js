import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'number_of_people_on_trip', 'number_of_passengers',
    'driver', 'driver_phone', 'reservation_id',
    'backup_driver', 'backup_driver_phone', 'backup_driver_phone_data']
  connect() {
    console.log("connect - driver")
  }

  editBackupDriversList() {
    var driver = this.driverTarget.value.split('-')[1]
    if (driver == "student") {
      var driver_id = this.driverTarget.value.split('-')[0]
    } else {
      var driver_id = 0
    }
    var reservation_id = this.reservation_idTarget.value
    fetch(`/reservations/get_drivers_list/${reservation_id}/${driver_id}`)
    .then((response) => response.json())
    .then((data) => this.updateBackupDriversSelect(data)
    );
  }

  updateBackupDriversSelect(data) {
    var backup_driver_selected = this.backup_driverTarget.value
    let dropdown = this.backup_driverTarget;
    dropdown.length = 0;
    var nothing_selected = true
    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.text = 'No Backup Driver';
    dropdown.add(defaultOption);
    if (data.length > 0) {
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        option.value = data[i][1];
        option.text = data[i][0]
        if (data[i][1] == backup_driver_selected) {
          option.selected = "selected"
          nothing_selected = false
        }
        dropdown.add(option);
      }
    }
    if (nothing_selected) {
      this.hideBackupDriverPhoneField()
    }
  }

  hideBackupDriverPhoneField() {
    var backup_driver_selected = this.backup_driverTarget.value
    var backup_driver_error_place = document.getElementById('backup_driver_error')

    if (backup_driver_selected) {
      this.backup_driver_phone_dataTarget.classList.add("fields--display")
      this.backup_driver_phone_dataTarget.classList.remove("fields--hide")
    }
    else {
      this.backup_driver_phoneTarget.value = ""
      backup_driver_error_place.innerHTML = ''
      this.backup_driver_phone_dataTarget.classList.add("fields--hide")
      this.backup_driver_phone_dataTarget.classList.remove("fields--display")
    }
  }

  submitForm(event) {
    var driver = this.driverTarget.value.split('-')[0]
    var driver_phone = this.driver_phoneTarget.value
    var number = this.number_of_people_on_tripTarget.value - this.number_of_passengersTarget.value  - 1
    var driver_error_place = document.getElementById('driver_error')
    driver_error_place.innerHTML = ''
    var backup_driver_error_place = document.getElementById('backup_driver_error')
    backup_driver_error_place.innerHTML = ''
    var regex = /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/im
    var submitForm = true

    if (driver == "" && driver_phone == "") {
      driver_error_place.innerHTML = "Please select a driver and enter driver's phone"
      submitForm = false
    } else if (driver != "" && driver_phone == "") {
      driver_error_place.innerHTML = "Please enter driver's phone"
      submitForm = false
    } else if (driver == "" && driver_phone != "") {
      driver_error_place.innerHTML = 'Please select a driver'
      submitForm = false
      if (!regex.test(driver_phone)) {
        driver_error_place.innerHTML += '<br>Phone number format is incorrect'
        submitForm = false
      }
    } else if (driver != "" && driver_phone != "") {
      if (regex.test(driver_phone)) {
        driver_error_place.innerHTML = ''
      } else {
        driver_error_place.innerHTML = 'Phone number format is incorrect'
        submitForm = false
      }
    } else {
      driver_error_place.innerHTML = ''
    }

    if (this.number_of_people_on_tripTarget.value > 1) { 
      var backup_driver = this.backup_driverTarget.value
      var backup_driver_phone = this.backup_driver_phoneTarget.value

      if (backup_driver != "" && number == 0) {
        backup_driver_error_place.innerHTML = 'Please remove one passenger then add a backup driver'
        submitForm = false
      } else if (backup_driver != "" && backup_driver_phone != "") {
        if (driver == backup_driver) {
          backup_driver_error_place.innerHTML = 'Driver and backup driver should be different'
          submitForm = false
        }
        if (driver_phone == backup_driver_phone) {
          backup_driver_error_place.innerHTML += "<br>Drivers' phones should be different"
          submitForm = false
        }
        if (!regex.test(backup_driver_phone)) {
          backup_driver_error_place.innerHTML += "<br>Backup driver's phone number format is incorrect"
          submitForm = false
        }
      } else if (backup_driver != "" && backup_driver_phone == "") {
        backup_driver_error_place.innerHTML = "Please enter backup driver's phone"
        submitForm = false
        if (driver == backup_driver) {
          backup_driver_error_place.innerHTML += '<br>Driver and backup driver should be different'
          submitForm = false
        }
      } else if (backup_driver == "" && backup_driver_phone != "") {
        backup_driver_error_place.innerHTML = "Please select a backup driver or remove a backup driver's phone"
        submitForm = false
        if (driver_phone == backup_driver_phone) {
          backup_driver_error_place.innerHTML += "<br>Drivers' phones should be different"
          submitForm = false
        }
        if (!regex.test(backup_driver_phone)) {
          backup_driver_error_place.innerHTML += "<br>Backup driver's phone number format is incorrect"
          submitForm = false
        }
      } else {
        backup_driver_error_place.innerHTML = ''
      }
    }

    if(submitForm == false) {
      event.preventDefault()
    }
    // else {
    //   Turbo.navigator.submitForm(this.formTarget)
    // }
  }

}
