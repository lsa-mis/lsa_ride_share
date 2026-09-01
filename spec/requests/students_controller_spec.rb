require 'rails_helper'

RSpec.describe Student, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }

  context 'with super_admin role' do
    let!(:super_admin_user) { FactoryBot.create(:user) }

    before do
      stub_super_admin_access(super_admin_user, unit)
      mock_login(super_admin_user)
    end

    it 'returns 200 for index' do
      student = FactoryBot.create(
        :student,
        program: program,
        first_name: 'Alpha',
        last_name: 'Tester',
        uniqname: 'alphatest'
      )

      get students_path

      expect(response).to have_http_status(200)
      expect(response.body).to include(student.display_name)
    end

    it 'returns student programs for selected uniqnames in turbo stream' do
      student = FactoryBot.create(
        :student,
        program: program,
        first_name: 'Bravo',
        last_name: 'Student',
        uniqname: 'bravostu'
      )

      get "/students/get_programs_for_uniqname/#{student.uniqname}", params: { format: :turbo_stream }

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include(student.display_name)
      expect(response.body).to include(program.title)
    end

    it 'only returns current term programs in get_programs_for_uniqname' do
      student_current = FactoryBot.create(
        :student,
        program: program,
        first_name: 'Current',
        last_name: 'Student',
        uniqname: 'shareduniq'
      )

      old_term = FactoryBot.create(
        :term,
        code: '1999',
        name: 'Old Term',
        classes_begin_date: Date.today - 2.years,
        classes_end_date: Date.today - 1.year
      )
      old_program = FactoryBot.create(:program, unit: unit, term: old_term, instructor: instructor, title: 'Old Program')
      FactoryBot.create(
        :student,
        program: old_program,
        first_name: 'Old',
        last_name: 'Student',
        uniqname: 'shareduniq'
      )

      get '/students/get_programs_for_uniqname/shareduniq', params: { format: :turbo_stream }

      expect(response).to have_http_status(200)
      expect(response.body).to include(student_current.display_name)
      expect(response.body).to include(program.title)
      expect(response.body).not_to include('Old Program')
    end
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get students_path
      expect(response).to have_http_status(200)
    end

    it 'filters index results by selected unit' do
      other_unit = FactoryBot.create(:unit)
      other_program = FactoryBot.create(:program, unit: other_unit, instructor: FactoryBot.create(:manager))

      in_unit_student = FactoryBot.create(
        :student,
        program: program,
        first_name: 'InUnit',
        last_name: 'Student',
        uniqname: 'inunit01'
      )
      out_unit_student = FactoryBot.create(
        :student,
        program: other_program,
        first_name: 'OutUnit',
        last_name: 'Student',
        uniqname: 'outunit01'
      )

      get students_path, params: { unit_id: unit.id }

      expect(response).to have_http_status(200)
      expect(response.body).to include(in_unit_student.display_name)
      expect(response.body).not_to include(out_unit_student.display_name)
    end

    it 'returns turbo stream for get_programs_for_uniqname' do
      student = FactoryBot.create(
        :student,
        program: program,
        first_name: 'Charlie',
        last_name: 'Student',
        uniqname: 'charliestu'
      )

      get "/students/get_programs_for_uniqname/#{student.uniqname}", params: { format: :turbo_stream }

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(response.body).to include(student.display_name)
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:student_record) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for get_programs_for_uniqname' do
      get '/students/get_programs_for_uniqname/someuniq', params: { format: :turbo_stream }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for get_programs_for_uniqname' do
      get '/students/get_programs_for_uniqname/someuniq', params: { format: :turbo_stream }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
