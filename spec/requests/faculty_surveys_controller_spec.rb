require 'rails_helper'

RSpec.describe FacultySurveysController, type: :request do
  let!(:unit) { FactoryBot.create(:unit) }
  let!(:term) do
    FactoryBot.create(
      :term,
      classes_begin_date: Date.today - 7.days,
      classes_end_date: Date.today + 30.days
    )
  end

  def create_faculty_survey_prefs(for_unit)
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'faculty_survey',
      description: 'Use faculty survey',
      pref_type: :boolean,
      on_off: true,
      value: ''
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'contact_phone',
      description: 'Contact phone',
      pref_type: :string,
      value: '734-000-0000'
    )
    FactoryBot.create(
      :unit_preference,
      unit: for_unit,
      name: 'notification_email',
      description: 'Notification email',
      pref_type: :string,
      value: 'notify@example.com'
    )
  end

  context 'with admin role' do
    let!(:admin_user) { FactoryBot.create(:user) }

    before do
      create_faculty_survey_prefs(unit)
      stub_admin_access(admin_user, unit)
      mock_login(admin_user)
      allow_any_instance_of(ApplicationController).to receive(:get_faculty_name_for_survey).and_return(
        {
          'valid' => true,
          'note' => '',
          'first_name' => 'Test',
          'last_name' => 'Faculty'
        }
      )
    end

    it 'returns 200 for index' do
      FactoryBot.create(:faculty_survey, unit: unit, term: term)

      get faculty_surveys_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Program Surveys')
    end

    it 'returns 200 for new' do
      get new_faculty_survey_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('New Program Survey')
    end

    it 'creates faculty survey and default config questions' do
      expect do
        post faculty_surveys_path, params: {
          faculty_survey: {
            title: 'My New Program Survey',
            uniqname: 'instructor1',
            term_id: term.id,
            unit_id: unit.id
          }
        }
      end.to change(FacultySurvey, :count).by(1)
        .and change(ConfigQuestion, :count).by(11)

      created = FacultySurvey.last
      expect(response).to have_http_status(302)
      expect(response).to redirect_to(faculty_survey_config_questions_path(created))
      expect(created.first_name).to eq('Test')
      expect(created.last_name).to eq('Faculty')
      expect(flash[:notice]).to include('Faculty survey was successfully created.')
    end

    it 'updates faculty survey and redirects to index filtered by term' do
      faculty_survey = FactoryBot.create(
        :faculty_survey,
        unit: unit,
        term: term,
        uniqname: 'instructor2',
        title: 'Original Title'
      )

      patch faculty_survey_path(faculty_survey), params: {
        faculty_survey: {
          title: 'Updated Survey Title',
          uniqname: faculty_survey.uniqname,
          term_id: term.id,
          unit_id: unit.id,
          first_name: faculty_survey.first_name,
          last_name: faculty_survey.last_name
        }
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(faculty_surveys_path(term_id: term.id))
      expect(faculty_survey.reload.title).to eq('Updated Survey Title')
      expect(flash[:notice]).to include('Faculty survey was successfully updated')
    end

    it 'sends faculty survey email and redirects to config questions' do
      faculty_survey = FactoryBot.create(
        :faculty_survey,
        unit: unit,
        term: term,
        uniqname: 'instructor3',
        first_name: 'First',
        last_name: 'Last'
      )

      get send_faculty_survey_email_path(faculty_survey)

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(faculty_survey_config_questions_path(faculty_survey))
      expect(flash[:notice]).to eq('Email was sent')
    end

    it 'destroys a faculty survey with turbo stream' do
      faculty_survey = FactoryBot.create(:faculty_survey, unit: unit, term: term)

      expect do
        delete faculty_survey_path(faculty_survey), params: { format: :turbo_stream }
      end.to change(FacultySurvey, :count).by(-1)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
    end
  end

  context 'with manager role' do
    let!(:manager_user) { FactoryBot.create(:user) }
    let!(:manager) { FactoryBot.create(:manager, uniqname: manager_user.uniqname) }
    let!(:manager_survey) do
      FactoryBot.create(
        :faculty_survey_with_config_question,
        unit: unit,
        term: term,
        uniqname: manager_user.uniqname,
        first_name: manager.first_name,
        last_name: manager.last_name
      )
    end

    before do
      create_faculty_survey_prefs(unit)
      stub_non_admin_access(manager_user)
      mock_login(manager_user)
    end

    it 'is not authorized for index' do
      get faculty_surveys_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_manager_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'returns 200 for surveys_index for own surveys' do
      manager_survey

      get surveys_index_path

      expect(response).to have_http_status(200)
      expect(response.body).to include('Your surveys')
    end
  end

  context 'with student role' do
    let!(:student_user) { FactoryBot.create(:user) }
    let!(:instructor) { FactoryBot.create(:manager) }
    let!(:program) { FactoryBot.create(:program, unit: unit, term: term, instructor: instructor) }
    let!(:student) { FactoryBot.create(:student, uniqname: student_user.uniqname, program: program) }

    before do
      create_faculty_survey_prefs(unit)
      stub_non_admin_access(student_user)
      mock_login(student_user)
    end

    it 'is not authorized for index' do
      get faculty_surveys_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for surveys_index' do
      get surveys_index_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(welcome_pages_student_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end

  context 'with none role' do
    let!(:user) { FactoryBot.create(:user) }

    before do
      create_faculty_survey_prefs(unit)
      stub_non_admin_access(user)
      mock_login(user)
    end

    it 'is not authorized for index' do
      get faculty_surveys_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end

    it 'is not authorized for surveys_index' do
      get surveys_index_path

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(all_root_path)
      expect(flash[:alert]).to include('You are not authorized to perform this action')
    end
  end
end
