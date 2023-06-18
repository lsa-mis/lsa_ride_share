import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['form', 'term', 'unit', 'program', 'site', 'required_fields',
    'day_start', 'number', 'start_time', 'end_time', 'selected_time_error', 'car', 'car_field']

  connect() {
    console.log("connect - reservation")
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

  setSites() {
    let program = this.programTarget.value
    fetch(`/programs/get_sites_list/${program}`)
        .then((response) => response.json())
        .then((data) => { this.updateSitesSelect(data);
    });
  }

  updateSitesSelect(data) {
    let dropdown = this.siteTarget;
    dropdown.length = 0;
    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      defaultOption.text = 'Select Site ...';
      dropdown.add(defaultOption);
    }
    dropdown.selectedIndex = 0;
    let option;
    for (let i = 0; i < data.length; i++) {
      option = document.createElement('option');
      option.value = data[i].id;
      option.text = data[i].title;
      dropdown.add(option);
    }
  }

  availableCars(event){
    let unit_id = this.unitTarget.value
    let day_start = this.day_startTarget.value
    let number = this.numberTarget.value
    let start_time = this.start_timeTarget.value
    let end_time = this.end_timeTarget.value
    let start_time_format = new Date(start_time)
    let end_time_format = new Date(end_time)
    let diff_time = parseInt(end_time_format - start_time_format)/60000;

    let time_field_error = document.getElementById('time_field')
    let required_fields_error = document.getElementById('required_fields')
    let car_field_error = document.getElementById('car_field')

    if (diff_time > 0 && diff_time < 31) {
      time_field_error.innerHTML = 'End time is too close to start time'
      required_fields_error.innerHTML = ''
      car_field_error.innerHTML = ''
    } else if (start_time_format > end_time_format) {
      time_field_error.innerHTML = 'Start time should occur before end time'
      required_fields_error.innerHTML = ''
      car_field_error.innerHTML = ''
    }else {
      time_field_error.innerHTML = ''
    }

    get(`/reservations/get_available_cars/${unit_id}/${day_start}/${number}/${start_time}/${end_time}`, {
      responseKind: "turbo-stream"
    })

  }

  submitForm(event) {
    let term = this.termTarget.value
    let program = this.programTarget.value
    let site = this.siteTarget.value
    let car = this.carTarget.value

    let start_time = this.start_timeTarget.value
    let end_time = this.end_timeTarget.value
    let start_time_format = new Date(start_time)
    let end_time_format = new Date(end_time)
    let diff_time = parseInt(end_time_format - start_time_format)/60000;
    
    let time_field_error = document.getElementById('time_field')
    let required_fields_error = document.getElementById('required_fields')
    let car_field_error = document.getElementById('car_field')
    let submitForm = true

    if(term == "" || program == "" || site == "") {
      required_fields_error.innerHTML = "Please select required data"
      car_field_error.innerHTML = ''
      submitForm = false
    } else if (car == "") {
      car_field_error.innerHTML = "Please select a car"
      required_fields_error.innerHTML = ''
      submitForm = false
    } else {
      required_fields_error.innerHTML = ''
      car_field_error.innerHTML = ''
    }

    if (diff_time < 31) {
      time_field_error.innerHTML = "End time is too close to the start time"
      submitForm = false
    } else {
      time_field_error.innerHTML = ''
    }

    if(submitForm == false) {
      event.preventDefault()
    }
    else {
      Turbo.navigator.submitForm(this.formTarget)
    }
  }

}
