import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['form', 'gas', 'unit','parking_spot', 'parking_other_div', 'parking_other']
  connect() {
    console.log("connect - createcar")
  }

  changeUnit() {
    let unit = this.unitTarget.value
    if (unit) {
      fetch(`/cars/get_parking_locations/${unit}`)
        .then((response) => response.json())
        .then((data) => this.updateParkingLocations(data)
        );
    } 
  }

  updateParkingLocations(data) {
    let dropdown = this.parking_spotTarget;
    dropdown.length = 0;
    let defaultOption = document.createElement('option');
    defaultOption.value = '';

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
      defaultOption.value = 'other';
      dropdown.add(defaultOption);
      this.addOtherParking()
    }
  }

  otherParking(){
    var parking_spot = this.parking_spotTarget.value.toLowerCase()
    var parking_other_error_place = document.getElementById('parking_other_error_place')

    if (parking_spot == 'other') {
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
    let unit = this.unitTarget.value
    var gas = this.gasTarget.value
    var unit_error_place = document.getElementById('unit_error_place')
    var gas_error_place = document.getElementById('gas_error')
    var parking_spot = this.parking_spotTarget.value.toLowerCase()
    var parking_other = this.parking_otherTarget.value
    var parking_other_error_place = document.getElementById('parking_other_error_place')
    var parking_spot_error_place = document.getElementById('parking_spot_error_place')
    var current_parking = document.getElementById('current_parking')
 
    unit_error_place.innerHTML = ''
    parking_other_error_place.innerHTML = ''
    parking_spot_error_place.innerHTML = ''
    gas_error_place.innerHTML = ''

    var submitForm = true

    if (!unit) {
      unit_error_place.innerHTML = "Unit must be selected"
      submitForm = false
    } else {
      if(gas == null || gas == "") {
        gas_error_place.innerHTML = "Percent of Fuel Remaining must be selected."
        submitForm = false
      }
      if((parking_spot == null || parking_spot == "") && current_parking == null){
        parking_spot_error_place.innerHTML = "Parking Spot must be selected."
        submitForm = false
      } else if(parking_spot == "other" && parking_other == "") {
        parking_other_error_place.innerHTML = "Please enter the other parking spot"
        submitForm = false
      } else if (parking_spot != "other"){
        this.parking_otherTarget.value = ""
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
