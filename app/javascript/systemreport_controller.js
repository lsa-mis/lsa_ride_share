import { Controller } from "@hotwired/stimulus"

export default class  extends Controller {
  static targets = ["form"]

  connect() {
    console.log("connect - system report")
  }

  submitForm(event) {
    console.log("connect - submitForm system report")
  }
}