require 'rails_helper'

RSpec.describe Student, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:send_reminders_pref) do
    FactoryBot.create(
      :unit_preference,
      unit: unit,
      name: 'send_reminders',
      description: 'Send reminder emails',
      pref_type: :boolean,
      on_off: false,
      value: ''
    )
  end
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
  let!(:student) { FactoryBot.create(:student, program: program) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get program_students_path(program)
      expect(response).to have_http_status(200)
    end

    it 'returns csv for index with format csv' do
      get program_students_path(program, format: :csv)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/csv')
    end

    it 'returns 200 for add_students' do
      get add_students_path(program.id)
      expect(response).to have_http_status(200)
    end

    it 'creates a student via turbo stream' do
      allow_any_instance_of(Programs::StudentsController).to receive(:get_name).and_return(
        { 'valid' => true, 'first_name' => 'New', 'last_name' => 'Student', 'note' => '' }
      )
      allow_any_instance_of(Programs::StudentsController).to receive(:is_member_of_admin_groups?).and_return(false)

      expect do
        post program_students_path(program, format: :turbo_stream), params: {
          student: {
            uniqname: 'newuniq',
            program_id: program.id,
            registered: false
          }
        }
      end.to change(Student, :count).by(1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(program.reload.number_of_students).to eq(program.students.count)
    end

    it 'updates a student and redirects to show' do
      patch program_student_path(program, student), params: {
        student: {
          uniqname: student.uniqname,
          program_id: program.id,
          first_name: 'Updated',
          last_name: student.last_name,
          canvas_course_complete_date: Date.today,
          meeting_with_admin_date: Date.today,
          phone_number: '7341111111'
        },
        mvr_status: '2031-01-01'
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(program_student_path(program, student))
      expect(student.reload.first_name).to eq('Updated')
      expect(student.reload.mvr_status).to eq('Approved until 2031-01-01')
    end

    it 'updates a single student mvr status via turbo stream' do
      allow_any_instance_of(Programs::StudentsController).to receive(:mvr_status).and_return(
        { 'success' => true, 'mvr_status' => 'Approved until 2031-12-31' }
      )

      get update_student_mvr_status_path(program.id, student.id, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(student.reload.mvr_status).to eq('Approved until 2031-12-31')
    end

    it 'updates canvas results for students without canvas date' do
      student.update!(canvas_course_complete_date: nil)
      allow_any_instance_of(Programs::StudentsController).to receive(:get_auth_token).and_return(
        { 'success' => true, 'access_token' => 'token' }
      )
      allow_any_instance_of(Programs::StudentsController).to receive(:canvas_readonly).and_return(
        { 'success' => true, 'data' => { student.uniqname => Date.today } }
      )

      get canvas_results_path(program.id, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(student.reload.canvas_course_complete_date).to eq(Date.today)
    end

    it 'updates canvas result for one student' do
      student.update!(canvas_course_complete_date: nil)
      allow_any_instance_of(Programs::StudentsController).to receive(:get_auth_token).and_return(
        { 'success' => true, 'access_token' => 'token' }
      )
      allow_any_instance_of(Programs::StudentsController).to receive(:canvas_readonly).and_return(
        { 'success' => true, 'data' => { student.uniqname => Date.today } }
      )

      get student_canvas_result_path(program.id, student.id, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(student.reload.canvas_course_complete_date).to eq(Date.today)
    end
  end

  context 'with manager as program instructor' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:instructor_program) do
      FactoryBot.create(
        :program,
        unit: unit,
        term: term,
        instructor: manager,
        title: 'Instructor Program'
      )
    end
    let!(:instructor_student) { FactoryBot.create(:student, program: instructor_program) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'returns 200 for index' do
      get program_students_path(instructor_program)
      expect(response).to have_http_status(200)
    end

    it 'returns 200 for add_students' do
      get add_students_path(instructor_program.id)
      expect(response).to have_http_status(200)
    end

    it 'deletes a student with no reservations via turbo stream' do
      delete program_student_path(instructor_program, instructor_student, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect { Student.find(instructor_student.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with manager not associated with the program' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get program_students_path(program)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student_record) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index' do
      get program_students_path(program)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for student_canvas_result' do
      get student_canvas_result_path(program.id, student.id, format: :turbo_stream)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
