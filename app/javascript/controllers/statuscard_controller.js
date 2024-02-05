import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "status_card", "more_button", "less_button" ]

  showStatusCard() {
    this.status_cardTarget.classList.remove("fields--hide")
    this.status_cardTarget.classList.add("fields--display")
    this.more_buttonTarget.classList.add("fields--hide")
    this.more_buttonTarget.classList.remove("fields--display")
    this.less_buttonTarget.classList.remove("fields--hide")
    this.less_buttonTarget.classList.add("fields--display")
  }

  hideStatusCard() {
    this.status_cardTarget.classList.add("fields--hide")
    this.status_cardTarget.classList.remove("fields--display")
    this.more_buttonTarget.classList.remove("fields--hide")
    this.more_buttonTarget.classList.add("fields--display")
    this.less_buttonTarget.classList.add("fields--hide")
    this.less_buttonTarget.classList.remove("fields--display")
  }

}
