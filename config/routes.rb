Rails.application.routes.draw do
 
  root to: "static_pages#home", as: :all_root

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.env.staging?
  
  get 'faculty_surveys/faculty_index', to: 'faculty_surveys#faculty_index', as: :faculty_index
  resources :faculty_surveys do
    resources :config_questions, module: :faculty_surveys
  end
  get '/faculty_surveys/survey/:faculty_survey_id', to: 'faculty_surveys/config_questions#survey', as: :survey
  post '/faculty_surveys/survey/:faculty_survey_id', to: 'faculty_surveys/config_questions#save_survey'
  get '/faculty_surveys/send_faculty_survey_email/:id', to: 'faculty_surveys#send_faculty_survey_email', as: :send_faculty_survey_email

  resources :units

  get 'unit_preference/:name', to: 'unit_preferences#delete_preference', as: :delete_preference
  get 'unit_preferences/unit_prefs', to: 'unit_preferences#unit_prefs', as: :unit_prefs
  post 'unit_preferences/unit_prefs/', to: 'unit_preferences#save_unit_prefs'
  resources :unit_preferences

  resources :terms
  resources :vehicle_reports do
    resources :notes, module: :vehicle_reports
  end
  
  post 'vehicle_reports/upload_image/:id', to: 'vehicle_reports#upload_image', as: :upload_image
  post 'vehicle_reports/upload_damage_images/:id', to: 'vehicle_reports#upload_damage_images', as: :upload_damage_images
  get 'vehicle_reports/delete_image/:id/:image_id/:image_field_name', to: 'vehicle_reports#delete_image', as: :delete_image, defaults: { format: :turbo_stream }

  get '/reservations/week_calendar/', to: 'reservations#week_calendar', as: 'week_calendar'
  resources :reservations do
    resources :vehicle_reports, module: :reservations
  end
  get '/reservations/get_available_cars/:unit_id/:day_start/:number/:start_time/:end_time', to: 'reservations#get_available_cars'
  get '/reservations/no_car_all_times/:unit_id/:day_start', to: 'reservations#no_car_all_times'
  get '/reservations/edit_change_day/:unit_id/:day_start', to: 'reservations#edit_change_day'
  patch '/reservations/add_non_uofm_passengers/:reservation_id', to: 'reservations#add_non_uofm_passengers', as: :add_non_uofm_passengers
  get '/reservations/add_passengers/:reservation_id', to: 'reservations/passengers#add_passengers', as: :add_passengers
  get '/reservations/add_passenger/:reservation_id', to: 'reservations/passengers#add_passenger', as: :add_passenger

  get '/reservations/add_drivers/:id', to: 'reservations#add_drivers', as: :add_drivers
  delete 'reservations/:reservation_id/:student_id', to: 'reservations/passengers#remove_passenger', as: :remove_passenger
  get '/reservations/day_reservations/:date', to: 'reservations#day_reservations', as: :day_reservations
  get '/reservations/:id/finish_reservation', to: 'reservations#finish_reservation', as: :finish_reservation
  get '/reservations/:id/update_passengers/', to: 'reservations#update_passengers', as: :update_passengers

  get 'send_reservation_updated_email/:id', to: 'reservations#send_reservation_updated_email', as: :send_reservation_updated_email

  resources :cars do
    resources :notes, module: :cars
  end
  
  resources :programs do
    resources :cars, module: :programs
  end
  resources :programs do
    resources :sites, module: :programs
  end
  get '/programs/sites/edit_program_sites/:program_id', to: 'programs/sites#edit_program_sites', as: :edit_program_sites
  delete 'programs/sites/:program_id/:id', to: 'programs/sites#remove_site_from_program', as: :remove_site_from_program
  get '/programs/get_programs_list/:unit_id/:term_id', to: 'programs#get_programs_list'
  get '/programs/get_students_list/:program_id', to: 'programs#get_students_list'
  get '/programs/get_sites_list/:program_id', to: 'programs#get_sites_list'

  resources :programs do
    resources :managers, module: :programs, only: [ :new, :create ]
  end
  get '/programs/managers/edit_program_managers/:program_id', to: 'programs/managers#edit_program_managers', as: :edit_program_managers
  delete 'programs/managers/remove_manager/:program_id/:id', to: 'programs/managers#remove_manager_from_program', as: :remove_manager_from_program

  resources :programs do
    resources :students, module: :programs
  end

  resources :students do
    resources :notes, module: :students
  end

  get '/programs/students/add_students/:program_id', to: 'programs/students#add_students', as: :add_students
  get '/programs/students/update_student_list/:program_id', to: 'programs/students#update_student_list', as: :update_student_list, defaults: { format: :turbo_stream }
  get '/programs/students/update_mvr_status/:program_id', to: 'programs/students#update_mvr_status', as: :update_mvr_status, defaults: { format: :turbo_stream }
  get '/programs/students/canvas_results/:program_id', to: 'programs/students#canvas_results', as: :canvas_results, defaults: { format: :turbo_stream }
  get '/programs/students/update_student_mvr_status/:program_id/:id', to: 'programs/students#update_student_mvr_status', as: :update_student_mvr_status, defaults: { format: :turbo_stream }
  get '/programs/students/student_canvas_result/:program_id/:id', to: 'programs/students#student_canvas_result', as: :student_canvas_result, defaults: { format: :turbo_stream }

  get 'programs/duplicate/:id', to: 'programs#duplicate', as: :duplicate
  delete 'programs/remove_car/:id/:car_id', to: 'programs#remove_car', as: :remove_car
  delete 'programs/remove_site/:id/:site_id', to: 'programs#remove_site', as: :remove_site
  delete 'programs/remove_config_question/:id/:config_question_id', to: 'programs#remove_config_question', as: :remove_config_question
  get 'programs/add_config_questions/:id/', to: 'programs#add_config_questions', as: :add_config_questions
  get 'programs/program_data/:id/', to: 'programs#program_data', as: :program_data

  get 'application/delete_file_attachment/:id', to: 'application#delete_file_attachment', as: :delete_file

  resources :sites do
    resources :notes, module: :sites
    resources :contacts, module: :sites
  end
  resources :notes

  get 'welcome_pages/student'
  
  get 'static_pages/home'

  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"} do
    delete 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end
end
