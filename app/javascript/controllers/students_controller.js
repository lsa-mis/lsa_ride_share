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
    console.log("Selected students:", selectedStudents);
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
}
