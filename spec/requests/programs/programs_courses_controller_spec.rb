require 'rails_helper'

RSpec.describe Course, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) { FactoryBot.create(:term) }
  let!(:instructor) { FactoryBot.create(:manager) }
  let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor, not_course: true) }
  let!(:course) { FactoryBot.create(:course, program: program) }

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
    end

    it 'returns 200 for index' do
      get program_courses_path(program)

      expect(response).to have_http_status(200)
      expect(response.body).to include('Courses List')
    end

    it 'returns 406 for new' do
      get new_program_course_path(program)

      expect(response).to have_http_status(406)
    end

    it 'creates a course via turbo stream and marks program as course-based' do
      program.update!(not_course: true)

      expect do
        post program_courses_path(program, format: :turbo_stream), params: {
          course: {
            subject: 'econ',
            catalog_number: '101',
            class_section: '001'
          }
        }
      end.to change(Course, :count).by(1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(Course.last.subject).to eq('ECON')
      expect(program.reload.not_course).to eq(false)
    end

    it 'returns 200 for edit' do
      get edit_program_course_path(program, course)

      expect(response).to have_http_status(200)
    end

    it 'updates a course and redirects to program courses index' do
      patch program_course_path(program, course), params: {
        course: {
          subject: 'math',
          catalog_number: '115',
          class_section: '300'
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(program_courses_path(program))
      expect(course.reload.subject).to eq('MATH')
      expect(course.reload.catalog_number).to eq('115')
    end

    it 'destroys course and sets program not_course true when it was the last one' do
      only_course = FactoryBot.create(:course, program: program, subject: 'BIO', catalog_number: '111', class_section: '101')
      program.courses.where.not(id: only_course.id).delete_all
      program.update!(not_course: false)

      delete program_course_path(program, only_course, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect { Course.find(only_course.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect(program.reload.not_course).to eq(true)
    end

    it 'destroys course and deletes students with no reservations' do
      student = FactoryBot.create(:student, program: program, course: course)

      delete program_course_path(program, course, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect { Student.find(student.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'keeps students with reservations but clears course and registration flag' do
      site = FactoryBot.create(:site, unit: unit)
      car = FactoryBot.create(:car, unit: unit)
      student_with_reservation = FactoryBot.create(:student, program: program, course: course, registered: true)
      FactoryBot.create(:reservation, program: program, site: site, car: car, driver: student_with_reservation)

      delete program_course_path(program, course, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect(student_with_reservation.reload.registered).to eq(false)
      expect(student_with_reservation.reload.course_id).to be_nil
    end
  end

  context 'with manager as instructor role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:manager_program) do
      FactoryBot.create(
        :program,
        unit: unit,
        term: term,
        instructor: manager,
        title: 'Manager Course Program'
      )
    end
    let!(:manager_course) { FactoryBot.create(:course, program: manager_program) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is authorized for index' do
      get program_courses_path(manager_program)

      expect(response).to have_http_status(200)
    end

    it 'is authorized for create' do
      expect do
        post program_courses_path(manager_program, format: :turbo_stream), params: {
          course: {
            subject: 'chem',
            catalog_number: '130',
            class_section: '010'
          }
        }
      end.to change(Course, :count).by(1)

      expect(response).to have_http_status(200)
    end

    it 'is authorized for destroy' do
      delete program_course_path(manager_program, manager_course, format: :turbo_stream)

      expect(response).to have_http_status(200)
      expect { Course.find(manager_course.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with manager not instructor for this program' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }

    before do
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get program_courses_path(program)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for update' do
      patch program_course_path(program, course), params: {
        course: {
          subject: 'fail',
          catalog_number: '000',
          class_section: '000'
        }
      }

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
      get program_courses_path(program)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for destroy' do
      delete program_course_path(program, course, format: :turbo_stream)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
