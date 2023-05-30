import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

// Connects to data-controller="program"
export default class extends Controller {
  static targets = ['form', 'term', 'unit', 'program', 'driver', 'backup_driver', 'site',
    'day_start', 'number', 'time_start', 'time_end']
  connect() {
    console.log("connect - reservation")
  }

  changePrograms() {
    console.log("changeProgram")
    var unit =this.unitTarget.value
    var term =this.termTarget.value
    if (unit && term) {
      console.log("unit:" + unit)
      console.log("term:" + term)
      fetch(`/programs/get_programs_list/${unit}/${term}`)
        .then((response) => response.json())
        .then((data) => this.updateProgramsSelect(data)
        );
    } else {
      console.log("no unit")
    }
  }
  updateProgramsSelect(data) {
    console.log("select" + data.length)
    console.log(data[0])
    let dropdown = this.programTarget;
    dropdown.length = 0;

    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      defaultOption.text = 'Select program...';

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
      this.setDriversAndSites()
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

  setDriversAndSites() {
    this.setSites()
    this.setDrivers()
    
  }

  setDrivers() {
    console.log("set drivers")
    var program = this.programTarget.value
    console.log(program)
    fetch(`/programs/get_students_list/${program}`)
        .then((response) => response.json())
        .then((data) => { this.updateDriversSelect(data);
        this.updateBackupDriversSelect(data);
    });
  }

  updateDriversSelect(data) {
    console.log(data)
    let dropdown = this.driverTarget;
    dropdown.length = 0;
    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      defaultOption.text = 'Select driver...';

      dropdown.add(defaultOption);
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        option.value = data[i].id;
        option.text = data[i].uniqname;
        dropdown.add(option);
      }
    }
  }

  updateBackupDriversSelect(data) {
    console.log(data)
    let dropdown = this.backup_driverTarget;
    dropdown.length = 0;
    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      defaultOption.text = 'Select driver...';

      dropdown.add(defaultOption);
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        option.value = data[i].id;
        option.text = data[i].uniqname;
        dropdown.add(option);
      }
    }
  }

  setSites() {
    console.log("set sites")
    var program = this.programTarget.value
    console.log(program)
    fetch(`/programs/get_sites_list/${program}`)
        .then((response) => response.json())
        .then((data) => { this.updateSitesSelect(data);
    });
  }

  updateSitesSelect(data) {
    console.log(data)
    let dropdown = this.siteTarget;
    dropdown.length = 0;
    let defaultOption = document.createElement('option');
    defaultOption.value = '';
    if (data.length > 1) {
      defaultOption.text = 'Select Site...';

      dropdown.add(defaultOption);
      dropdown.selectedIndex = 0;
      let option;
      for (let i = 0; i < data.length; i++) {
        option = document.createElement('option');
        option.value = data[i].id;
        option.text = data[i].title;
        dropdown.add(option);
      }
    }
  }

  availableCars(){
    console.log("availableCars")
    var day_start = this.day_startTarget.value
    var number = this.numberTarget.value
    var time_start = this.time_startTarget.value
    var time_end = this.time_endTarget.value
    console.log(day_start)
    console.log(number)
    console.log(time_start)
    console.log(time_end)

    get(`/reservations/get_available_cars/${day_start}/${number}/${time_start}/${time_end}`, {
      responseKind: "turbo-stream"
    })
  }
}