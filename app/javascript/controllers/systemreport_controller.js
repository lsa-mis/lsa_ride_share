import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["format", "unit", "term"]

  connect() {
    console.log("connect - system report")
  }

  saveLink() {
    var format = this.formatTarget.value
    var unit = this.unitTarget.value
    var term = this.termTarget.value

    var needsAmp = false

    console.log(format)

    var a = document.getElementById('csv_link'); 
    //a.href = "run_report?term_id= " + term + "&unit_id=" + unit + "&format=csv&commit=Run+report"
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

    if(needsAmp == true) {
      a.href = a.href + "&"
      needsAmp = false
    }

    a.href = a.href + "format=csv&commit=Run+report"

    a.style.display = "block"

  }

  submitForm(event) {
    console.log("connect - submitForm system report")
  }


}