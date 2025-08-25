import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { scrollToTop: Boolean }

  connect() {
    console.log("Flash controller connected")
    // Only scroll to top if the data attribute is set to true
    if (this.scrollToTopValue == true) {
      this.scrollToTop()
    }
  }

  scrollToTop() {
    // Use setTimeout to ensure DOM is fully rendered
    setTimeout(() => {
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }, 50)
  }
}
