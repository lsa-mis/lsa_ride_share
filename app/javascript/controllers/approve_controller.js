import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form']
  
  connect () {
    console.log("connect approve")
  }

  cancelReservation() {
    console.log("cancel")
  }


  toggleApprove(event) {
    var car = document.getElementById("car").textContent
    var driver = document.getElementById("driver").textContent
    var approve_error = document.getElementById("approve_error")
    var check = document.getElementById("reservation_approved")
    if (check.checked) {
      if (car.includes("No car selected") || driver.includes("No driver selected")) {
        approve_error.innerHTML = "Do not approve if a car or a driver is not selected"
        check.checked = false
        event.preventDefault()
      }
    } else {
      approve_error.innerHTML = ""
      Turbo.navigator.submitForm(this.formTarget)
    }
  }
}
