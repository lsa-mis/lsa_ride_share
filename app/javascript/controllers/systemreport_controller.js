import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["format", "unit", "term", "program", "runreportbutton"]

  connect() {
    console.log("connect - system report")
  }

  saveLink() {
    var format = this.formatTarget.value
    var unit = this.unitTarget.value
    var term = this.termTarget.value
    var program = this.programTarget.value

    var needsAmp = false

    console.log(format)

    var a = document.getElementById('csv_link'); 

    a.href = "run_report?"

    if(term != "") {
      a.href = a.href + "term_id=" + term
      needsAmp = true
    }
    if(unit != "") {
      if(needsAmp == true) {
        a.href = a.href + "&"
        needsAmp = false
      }
      a.href = a.href + "unit_id=" + unit
      needsAmp = true
    }
    if(program != "") {
      if(needsAmp == true) {
        a.href = a.href + "&"
        needsAmp = false
      }
      a.href = a.href + "program_id=" + program
      needsAmp = true
    }

    if(needsAmp == true) {
      a.href = a.href + "&"
      needsAmp = false
    }

    a.href = a.href + "format=csv&commit=Run+report"

    if(a.style.display == "none") {
      a.style.display = "block"
      this.runreportbuttonTarget.classList.add("fields--hide")
      this.runreportbuttonTarget.classList.remove("fields--display")
    }
    else {
      a.style.display = "none"
      this.runreportbuttonTarget.classList.add("fields--display")
      this.runreportbuttonTarget.classList.remove("fields--hide")
    }

  }

  submitForm(event) {
    console.log("connect - submitForm system report")
  }


}