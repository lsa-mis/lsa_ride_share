import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'phone_number']
  connect() {
    console.log("connect - phone")
  }

  submitForm(event) {
    var phone_number = this.phone_numberTarget.value
    var phone_error_place = document.getElementById('phone_error')
    phone_error_place.innerHTML = ''
    var regex = /^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/im
    console.log(phone_error_place)
    if (!regex.test(phone_number)) {
      console.log(phone_number)
      console.log("hell")
      phone_error_place.innerHTML += '<br>Phone number format is incorrect'
      console.log(phone_error_place)
      event.preventDefault()
    }

    // else {
    //   Turbo.navigator.submitForm(this.formTarget)
    // }
  }

}
