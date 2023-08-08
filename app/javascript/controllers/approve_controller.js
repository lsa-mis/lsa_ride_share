import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"
export default class extends Controller {
  static targets = ['form', 'cancel_type', 'reservation_id']
  
  connect () {
    console.log("connect approve")
  }

  cancelReservation() {
    console.log("cancel")
    var cancel_type = this.cancel_typeTarget.value
    var reservation_id = this.reservation_idTarget.value

    get(`/reservations/cancel_recurring_reservation/${cancel_type}/${reservation_id}`, {
      responseKind: "html"
    })

  }


  toggleApprove(event) {
    console.log("approve")
    var car = document.getElementById("car").textContent
    var driver = document.getElementById("driver").textContent
    var approve_error = document.getElementById("approve_error")
    var check = document.getElementById("reservation_approved")
    if (check.checked) {
      if (car.includes("No car selected") || driver.includes("No driver selected")) {
        approve_error.innerHTML = "Do not approve if a car or a driver is not selected"
        check.checked = false
        event.preventDefault()
      } else {
        approve_error.innerHTML = ""
        Turbo.navigator.submitForm(this.formTarget)
      }
    } else {
      Turbo.navigator.submitForm(this.formTarget)
    }
  }
}
