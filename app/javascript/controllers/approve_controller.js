import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form']
  
  connect () {
    console.log("connect approve")
  }

  toggleApprove() {
    console.log("here")
    Turbo.navigator.submitForm(this.formTarget)
  }
}