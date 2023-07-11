import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['form']
  
  connect () {
    console.log("passengers")
  }
  search() {
    console.log("here")
    Turbo.navigator.submitForm(this.formTarget)
  }
}
