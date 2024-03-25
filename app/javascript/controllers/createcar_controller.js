import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['unit','parking_spot', 'parking_other_div', 'parking_other']
  connect() {
    console.log("connect - createcar")
  }

  changeUnit() {
    let unit = this.unitTarget.value
    console.log(unit)
    if (unit) {
      fetch(`/cars/get_parking_locations/${unit}`)
        .then((response) => response.json())
        .then((data) => this.updateParkingLocations(data)
        );
    } else {
      console.log("no unit")
    }
  }

  updateParkingLocations(data) {
    console.log (data)
    let dropdown = this.parking_spotTarget;
    dropdown.length = 0;
    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    console.log(dropdown)

    if (data.length > 1) {
      this.removeOtherParking()
      defaultOption.text = 'Select ...';
      dropdown.add(defaultOption);
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        option.value = data[i];
        option.text = data[i]
        dropdown.add(option);
      }
    } else if (data.length == 1) {
      this.removeOtherParking()
      dropdown.selectedIndex = 0;
      let option;
      option = document.createElement('option');
      option.value = data[0].id;
      option.text = data[0]
      dropdown.add(option);
    } else {
      defaultOption.text = 'No parking locations';
      dropdown.add(defaultOption);
      this.addOtherParking()
    }
  }

  otherParking(){
    var parking_spot = this.parking_spotTarget.value.toLowerCase()
    var parking_other_error_place = document.getElementById('parking_other_error_place')
    if (parking_spot == 'other') {
      console.log("hell")
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

  addOtherParking() {
    this.parking_otherTarget.value = ""
    this.parking_other_divTarget.classList.remove("fields--hide")
    this.parking_other_divTarget.classList.add("fields--display")
  }

  removeOtherParking() {
    this.parking_otherTarget.value = ""
    this.parking_other_divTarget.classList.add("fields--hide")
    this.parking_other_divTarget.classList.remove("fields--display")
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
