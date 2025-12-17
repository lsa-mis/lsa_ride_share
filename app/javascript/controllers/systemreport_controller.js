import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "format", "unit", "term", "program", 'student', 'uniqname', "report_type",
  "run_report_button", "download_report_button", "reportRun"]

  connect() {
    console.log("connect - system report")
    this.initializeCSVOption()
  }

  changePrograms() {
    console.log("change programs")
    let unit = this.unitTarget.value
    let term = this.termTarget.value
    console.log("unit:", unit, "term:", term)
    if (unit && term) {
      fetch(`/programs/get_programs_list/${unit}/${term}`)
        .then((response) => response.json())
        .then((data) => this.updateProgramsSelect(data)
        );
    } else {
      console.log("no unit or term - unit:", unit, "term:", term)
    }
  }

  updateProgramsSelect(data) {
    console.log("update programs - data length:", data.length)
    let dropdown = this.programTarget;
    dropdown.length = 0;

    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      console.log("multiple programs")
      defaultOption.text = 'All Programs';
      dropdown.add(defaultOption);
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        console.log(option)
        option.value = data[i][0];
        option.text = data[i][1];
        //option.text = this.programTitle(data[i])
        dropdown.add(option);
      }
    } else if (data.length == 1) {
      console.log("one program")
      dropdown.selectedIndex = 0;
      let option;
      option = document.createElement('option');
      option.value = data[0][0];
      option.text = data[0][1];
      dropdown.add(option);
      if (this.hasStudentTarget) {
        this.getStudents();
      }
    } else {
      console.log("no programs")
      defaultOption.text = 'No programs for this term';
      dropdown.add(defaultOption);
    }
  }

  programTitle(program) {
    if (program.not_course) {
      var title = program.title + ' - not a course'
    } else {
      var title = program.title
    }
    return title
  }

  getStudents() {
    let program =this.programTarget.value
    if (program) {
      fetch(`/programs/get_students_list/${program}`)
        .then((response) => response.json())
        .then((data) => this.updateStudentsSelect(data)
        );
    }
  }

  updateStudentsSelect(data) {
    let dropdown = this.studentTarget;
    dropdown.length = 0;

    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      defaultOption.text = 'Select Student ...';
      dropdown.add(defaultOption);
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        option.value = data[i].id;
        option.text = this.studentName(data[i])
        dropdown.add(option);
      }
    } else if (data.length == 1) {
      dropdown.selectedIndex = 0;
      let option;
      option = document.createElement('option');
      option.value = data[0].id;
      option.text = this.studentName(data[0])
      dropdown.add(option);
    } else {
      defaultOption.text = 'No students for this program';
      dropdown.add(defaultOption);
    }
  }

  studentName(student) {
    var name = student.first_name + " " +student.last_name
    return name
  }

  saveLink() {
    var format = this.formatTarget.value
    var reportHasRun = this.reportRunTarget.value === "true"
    
    // Prevent CSV selection if report hasn't been run
    if (format === "csv" && !reportHasRun) {
      alert("Please run the report with 'Display in a browser' first before exporting to CSV.")
      this.formatTarget.value = "html"
      return
    }
    
    var unit = this.unitTarget.value
    var term = this.termTarget.value
    var program = this.programTarget.value
    if (this.hasStudentTarget) {
      var student = this.studentTarget.value
    }
    var report_type = this.report_typeTarget.value

    var needsAmp = false
    var a = document.getElementById('csv_link');
    var report_method = report_type + "_report"
    a.href = "/system_reports/" + report_method + "?"

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
    if(student != "") {
      if(needsAmp == true) {
        a.href = a.href + "&"
        needsAmp = false
      }
      a.href = a.href + "student_id=" + student
      needsAmp = true
    }
    if(needsAmp == true) {
      a.href = a.href + "&"
      needsAmp = false
    }

    a.href += "report_type=" + report_type + "&"
    a.href = a.href + "format=csv&commit=Run+report"

    if(format == "csv" && reportHasRun) {
      this.run_report_buttonTarget.classList.add("fields--hide")
      this.run_report_buttonTarget.classList.remove("fields--display")
      this.download_report_buttonTarget.classList.remove("fields--hide")
      this.download_report_buttonTarget.classList.add("fields--display")
      this.enableDownloadButton()
    }
    else {
      this.download_report_buttonTarget.classList.add("fields--hide")
      this.download_report_buttonTarget.classList.remove("fields--display")
      this.run_report_buttonTarget.classList.remove("fields--hide")
      this.run_report_buttonTarget.classList.add("fields--display")
    }
  }

  submitForm(event) {
    console.log("submit form")
    let term = this.termTarget.value
    let unit = this.unitTarget.value
    let report_type = this.report_typeTarget.value
    let error_text = document.getElementById('error_text')
    error_text.innerHTML = ""
    if(term == "" || unit == "") {
      error_text.innerHTML = "Please select required fields ( * )"
      event.preventDefault()
    }
    else if (report_type == "reservations_for_student") {
      let student = this.studentTarget.value
      let uniqname = this.uniqnameTarget.value
      if (student == "" && uniqname == "") {
        error_text.innerHTML = "For this report please select a program and a student or type a uniqname"
        event.preventDefault()
      }
    }
    else {
      error_text.innerHTML = ""
      console.log("form valid")
      // Don't mark report as run here - wait for actual content to load
    }
  }

  initializeCSVOption() {
    // Check if there's already report data on page load
    this.checkForExistingReportData()
    
    // Disable CSV option initially if no data
    if (this.reportRunTarget.value !== "true") {
      this.disableCSVOption()
      this.disableDownloadButton()
    }
  }

  checkForExistingReportData() {
    const reportTable = document.querySelector('.report_table')
    const reportData = document.querySelector('#report_table')
    
    if (reportTable || (reportData && reportData.innerHTML.trim() !== '')) {
      this.reportRunTarget.value = "true"
      this.enableCSVOption()
      console.log("existing report data found on page load")
    } else {
      this.reportRunTarget.value = "false"
      console.log("no existing report data found")
    }
  }

  markReportAsRun() {
    // Check if there's actual report data on the page
    const reportTable = document.querySelector('.report_table')
    const reportData = document.querySelector('#report_table')
    
    if (reportTable && reportData.innerHTML.trim() !== '') {
      this.reportRunTarget.value = "true"
      this.enableCSVOption()
      console.log("report marked as run - data found on page")
    } else {
      console.log("no report data found, not marking as run")
    }
  }

  enableCSVOption() {
    let csvOption = this.formatTarget.querySelector('option[value="csv"]')
    if (csvOption) {
      csvOption.disabled = false
      csvOption.textContent = "Export to CSV"
    }
  }

  disableCSVOption() {
    let csvOption = this.formatTarget.querySelector('option[value="csv"]')
    if (csvOption) {
      csvOption.disabled = true
      csvOption.textContent = "Export to CSV (Run report first)"
    }
  }

  enableDownloadButton() {
    let downloadLink = document.getElementById('csv_link')
    downloadLink.classList.remove('opacity-50', 'pointer-events-none')
  }

  disableDownloadButton() {
    let downloadLink = document.getElementById('csv_link')
    downloadLink.classList.add('opacity-50', 'pointer-events-none')
  }

  clearFilters() {
    var url = window.location.pathname
    this.reportRunTarget.value = "false"
    this.disableCSVOption()
    this.disableDownloadButton()
    Turbo.visit(url)
  }

}
