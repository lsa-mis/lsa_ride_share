import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

export default class extends Controller {
  static targets = ['form', 'uniqname']
  
  connect () {
    console.log("connect students")
  }
  search() {
    Turbo.navigator.submitForm(this.formTarget)
  }

  selectPrograms() {
    var selectedStudents = this.uniqnameTargets.filter(checkbox => checkbox.checked).map(checkbox => checkbox.value);
    if (selectedStudents.length > 0) {
      get(`/students/get_programs_for_uniqname/${selectedStudents.join(",")}`, {
        responseKind: "turbo-stream"
      })
    }
    if (selectedStudents.length === 0) {
      const turboStream = `
        <turbo-stream action="update" target="students_programs">
          <template>
            <p class="m-2">No students are selected.</p>
          </template>
        </turbo-stream>
      `;
      Turbo.renderStreamMessage(turboStream);
    }
  }

  filterCheckboxes(event) {
    const filterText = event.target.value;
    const containerId = event.target.getAttribute('data-filter-target');
    const container = document.getElementById(containerId);
    const checkboxes = container.querySelectorAll(".form-check");

    const lowerFilter = filterText.toLowerCase();

    checkboxes.forEach((checkbox) => {
      const label = checkbox.textContent.toLowerCase();
      if (label.includes(lowerFilter)) {
        checkbox.style.display = "";
      } else {
        checkbox.style.display = "none";
      }
    });
  }
}
