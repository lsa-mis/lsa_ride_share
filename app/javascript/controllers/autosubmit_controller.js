import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form']
  
  connect () {
    console.log("connect autosubmit")
  }
  search() {
    Turbo.navigator.submitForm(this.formTarget)
  }
}
