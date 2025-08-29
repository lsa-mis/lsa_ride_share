import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'phone_number']
  connect() {
    console.log("connect - phone")
  }

  submitForm(event) {
    var phone_number = this.phone_numberTarget.value
    if (document.getElementById('phone_error_desktop')) {
      var phone_error_desktop_place = document.getElementById('phone_error_desktop')
      phone_error_desktop_place.innerHTML = ''
    }
    if (document.getElementById('phone_error_mobile')) {
      var phone_error_mobile_place = document.getElementById('phone_error_mobile')
      phone_error_mobile_place.innerHTML = ''
    }
    if (phone_number.trim() != '') {
      var regex = /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/im
      if (!regex.test(phone_number)) {
        if (typeof phone_error_desktop_place !== 'undefined') {
          phone_error_desktop_place.innerHTML = '<br>Phone number format is incorrect'
        }
        if (typeof phone_error_mobile_place !== 'undefined') {
          phone_error_mobile_place.innerHTML = '<br>Phone number format is incorrect'
        }
        event.preventDefault()
      }
    }

    // else {
    //   Turbo.navigator.submitForm(this.formTarget)
    // }
  }

}
