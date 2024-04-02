import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox_all", "checkbox", "form"]

  connect() {
    console.log("connect - checkbox select/deselect all")
    this.checkboxTargets.map(x => x.checked = false)
    this.checkbox_allTarget.checked = false
  }

  toggleCheckbox() {
    if (this.checkbox_allTarget.checked) {
      this.checkboxTargets.map(x => x.checked = true)
      // this.checkboxTargets.forEach((checkbox) => {
      //   checkbox.checked = true
      // })
    } else {
      this.checkboxTargets.map(x => x.checked = false)
    }
  }

  toggleCheckboxAll() {
    if (this.checkboxTargets.map(x => x.checked).includes(false)) {
      this.checkbox_allTarget.checked = false
    } else {
      this.checkbox_allTarget.checked = true
    }
  }

  submitForm(event) {
    var checkbox_error_place = document.getElementById('checkbox_error')
    checkbox_error_place.innerHTML = ''
    if (!this.checkboxTargets.map(x => x.checked).includes(true)) {
      checkbox_error_place.innerHTML = "Please select reservations."
      event.preventDefault()
    }
  }
}
