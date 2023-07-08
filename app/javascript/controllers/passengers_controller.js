import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form', 'number_of_people_on_trip', 'number_of_non_uofm_passengers',
    'current_number_of_non_uofm_passengers']
  connect() {
    console.log("connect - passenger")
  }

  submitForm(event) {
    var added_people = Number(document.getElementById("added_people").textContent);
    var number_on_trip = Number(this.number_of_people_on_tripTarget.value)
    var current_non_uofm_on_trip = Number(this.current_number_of_non_uofm_passengersTarget.value)
    var non_uofm_number = Number(this.number_of_non_uofm_passengersTarget.value)
    var error_place = document.getElementById('error_place')

    if (added_people - current_non_uofm_on_trip + non_uofm_number > number_on_trip) {
      error_place.innerHTML = added_people + " are people already added to the trip, there is no space for " +
      non_uofm_number + " non UofM passenger(s)"
      event.preventDefault()
    } else {
      error_place.innerHTML = ""
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
