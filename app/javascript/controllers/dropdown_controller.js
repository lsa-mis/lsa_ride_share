import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  connect() {
    this.isOpen = false
  }

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.isOpen = true
    this.menuTarget.classList.remove("invisible")
    this.buttonTarget.setAttribute("aria-expanded", "true")
    document.addEventListener("click", this.handleOutsideClick)
  }

  close() {
    this.isOpen = false
    this.menuTarget.classList.add("invisible")  
    this.buttonTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.handleOutsideClick)
  }

  handleKeydown(event) {
    switch (event.key) {
      case "Enter":
      case " ": // Space
        event.preventDefault()
        this.toggle()
        break
      case "Escape":
        if (this.isOpen) {
          this.close()
        }
        break
    }
  }

  // Clean up event listener on controller disconnect
  disconnect() {
    if (this.isOpen) {
      document.removeEventListener("click", this.handleOutsideClick)
    }
  }

  handleOutsideClick = (event) => {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
}
