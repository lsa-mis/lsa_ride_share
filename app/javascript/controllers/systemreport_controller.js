import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "format", "unit", "term", "program",
  "run_report_button", "download_report_button", "report_type"]

  connect() {
    console.log("connect - system report")
  }

  changePrograms() {
    let unit =this.unitTarget.value
    let term =this.termTarget.value
    if (unit && term) {
      fetch(`/programs/get_programs_list/${unit}/${term}`)
        .then((response) => response.json())
        .then((data) => this.updateProgramsSelect(data)
        );
    } else {
      console.log("no unit")
    }
  }

  updateProgramsSelect(data) {
    let dropdown = this.programTarget;
    dropdown.length = 0;

    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      defaultOption.text = 'Select Program ...';
      dropdown.add(defaultOption);
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        option.value = data[i].id;
        // option.text = data[i].title;
        option.text = this.programTitle(data[i])
        dropdown.add(option);
      }
    } else if (data.length == 1) {
      dropdown.selectedIndex = 0;
      let option;
      option = document.createElement('option');
      option.value = data[0].id;
      // option.text = data[0].title;
      option.text = this.programTitle(data[0])
      dropdown.add(option);
      this.setSites()
    } else {
      defaultOption.text = 'No programs for this term';
      dropdown.add(defaultOption);
    }
  }

  programTitle(program) {
    if (program.not_course) {
      var title = program.title + ' - not a course'
    } else {
      var title = program.title + " - " + program.subject + " " + program.catalog_number
    }
    return title
  }

  saveLink() {
    var format = this.formatTarget.value
    var unit = this.unitTarget.value
    var term = this.termTarget.value
    var program = this.programTarget.value
    var report_type = this.report_typeTarget.value

    var needsAmp = false
    var a = document.getElementById('csv_link'); 
    a.href = "/system_reports/run_report?"

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

    a.href += "report_type=" + report_type + "&"
    a.href = a.href + "format=csv&commit=Run+report"

    if(format == "csv") {
      this.run_report_buttonTarget.classList.add("fields--hide")
      this.run_report_buttonTarget.classList.remove("fields--display")
      this.download_report_buttonTarget.classList.remove("fields--hide")
      this.download_report_buttonTarget.classList.add("fields--display")
    }
    else {
      this.download_report_buttonTarget.classList.add("fields--hide")
      this.download_report_buttonTarget.classList.remove("fields--display")
      this.run_report_buttonTarget.classList.remove("fields--hide")
      this.run_report_buttonTarget.classList.add("fields--display")
    }
  }

  submitForm(event) {
    let term = this.termTarget.value
    let unit = this.unitTarget.value
    let error_text = document.getElementById('error_text')

    if(term == "" || unit == "") {
      console.log("hell")
      console.log(error_text)
      error_text.innerHTML = "Please select required fields ( * )"
      event.preventDefault()
    }
    else {
      error_text.innerHTML = ""
    }
  }

}