import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="program"
export default class extends Controller {
  static targets = ['course_data', 'hide_course_data', 'form', 'subject', 'catalog_number', 'class_section', 'course_error']
  connect() {
  }

  hideCourseFields() {
    var hide = document.getElementById("program_not_course").checked
    if (hide) {
      this.subjectTarget.value = ""
      this.catalog_numberTarget.value = ""
      this.class_sectionTarget.value = ""
      this.course_dataTarget.classList.add("fields--hide")
      this.course_dataTarget.classList.remove("fields--display")
    }
    else {
      this.course_dataTarget.classList.add("fields--display")
      this.course_dataTarget.classList.remove("fields--hide")
    }
  }

  submitForm(event) {
    var hide = document.getElementById("program_not_course").checked
    if (hide) {
      this.course_errorTarget.classList.remove("fields--display")
        this.course_errorTarget.classList.add("fields--hide")
        Turbo.navigator.submitForm(this.formTarget)
      }
    else {
      this.course_errorTarget.classList.remove("fields--display")
      this.course_errorTarget.classList.add("fields--hide")
      Turbo.navigator.submitForm(this.formTarget)
      var subject = this.subjectTarget.value
      var catalog_number = this.catalog_numberTarget.value
      var class_section = this.class_sectionTarget.value
      if(subject == "" && catalog_number == "" && class_section == "") {
        this.course_errorTarget.classList.add("fields--display")
        this.course_errorTarget.classList.remove("fields--hide")
        event.preventDefault()
      }
    }
  }
}
