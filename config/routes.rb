Rails.application.routes.draw do
  get 'system_reports/', to: 'system_reports#index'
  get 'system_reports/run_report/', to: 'system_reports#run_report', as: :run_report
 
  root to: "static_pages#home", as: :all_root

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.env.staging?
  
  get 'program_surveys/surveys_index', to: 'faculty_surveys#surveys_index', as: :surveys_index
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

  get "vehicle_reports/download_vehicle_damage_form/", to: 'vehicle_reports#download_vehicle_damage_form', as: :download_vehicle_damage_form
  resources :vehicle_reports do
    resources :notes, module: :vehicle_reports
  end
  post 'vehicle_reports/upload_image/:id', to: 'vehicle_reports#upload_image', as: :upload_image
  post 'vehicle_reports/upload_damage_images/:id', to: 'vehicle_reports#upload_damage_images', as: :upload_damage_images
  post 'vehicle_reports/upload_damage_form/:id', to: 'vehicle_reports#upload_damage_form', as: :upload_damage_form
  get 'vehicle_reports/delete_image/:id/:image_id/:image_field_name', to: 'vehicle_reports#delete_image', as: :delete_image, defaults: { format: :turbo_stream }
  get 'vehicle_reports/delete_damage_form/:id/:image_id/', to: 'vehicle_reports#delete_damage_form', as: :delete_damage_form, defaults: { format: :turbo_stream }

  get '/reservations/new_long', to: 'reservations#new_long', as: :new_long_reservation
  get '/reservations/edit_long/:id', to: 'reservations#edit_long', as: :edit_long_reservation
  get '/reservations/week_calendar/', to: 'reservations#week_calendar', as: 'week_calendar'
  resources :reservations do
    resources :vehicle_reports, module: :reservations
  end
  get '/reservations/get_available_cars/:unit_id/:day_start/:number/:start_time/:end_time/:until_date', to: 'reservations#get_available_cars'
  get '/reservations/get_available_cars_long/:unit_id/:day_start/:day_end/:number/:start_time/:end_time/:until_date', to: 'reservations#get_available_cars_long'
  get '/reservations/no_car_all_times/:unit_id/:day_start/:start_time/:end_time', to: 'reservations#no_car_all_times'
  get '/reservations/edit_change_day/:unit_id/:day_start/:start_time/:end_time', to: 'reservations#edit_change_day'
  get '/reservations/change_start_end_day/:unit_id/:day_start/:day_end/:start_time/:end_time', to: 'reservations#change_start_end_day'

  patch '/reservations/add_non_uofm_passengers/:reservation_id', to: 'reservations#add_non_uofm_passengers', as: :add_non_uofm_passengers
  get '/reservations/add_passengers/:reservation_id', to: 'reservations/passengers#add_passengers', as: :add_passengers
  get '/reservations/add_passenger/:reservation_id', to: 'reservations/passengers#add_passenger', as: :add_passenger

  get '/reservations/get_drivers_list/:id/:driver_id', to: 'reservations#get_drivers_list', as: :get_drivers_list

  get '/reservations/add_drivers/:id', to: 'reservations#add_drivers', as: :add_drivers
  patch '/reservations/add_edit_drivers/:id', to: 'reservations#add_edit_drivers', as: :add_edit_drivers

  delete 'reservations/:reservation_id/:id/:resource', to: 'reservations/passengers#remove_passenger', as: :remove_passenger

  get '/reservations/day_reservations/:date', to: 'reservations#day_reservations', as: :day_reservations
  get '/reservations/:id/add_drivers_later', to: 'reservations#add_drivers_later', as: :add_drivers_later
  get '/reservations/:id/finish_reservation', to: 'reservations#finish_reservation', as: :finish_reservation
  get '/reservations/:id/update_passengers/', to: 'reservations#update_passengers', as: :update_passengers
  post '/reservations/cancel_recurring_reservation/:id', to: 'reservations#cancel_recurring_reservation', as: :cancel_recurring_reservation
  get '/send_reservation_updated_email/:id', to: 'reservations#send_reservation_updated_email', as: :send_reservation_updated_email
  get '/approve_all_recurring/:id', to: 'reservations#approve_all_recurring', as: :approve_all_recurring

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

  get '/managers/update_managers_mvr_status', to: 'managers#update_managers_mvr_status', as: :update_managers_mvr_status, defaults: { format: :turbo_stream }
  resources :managers

  get '/programs/managers/edit_program_managers/:program_id', to: 'programs/managers#edit_program_managers', as: :edit_program_managers
  delete 'programs/managers/remove_manager/:program_id/:id', to: 'programs/managers#remove_manager_from_program', as: :remove_manager_from_program

  resources :programs do
    resources :students, module: :programs
  end

  resources :programs do
    resources :courses, module: :programs
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

  get 'application/delete_file_attachment/:id', to: 'application#delete_file_attachment', as: :delete_file

  resources :sites do
    resources :notes, module: :sites
    resources :contacts, module: :sites
  end
  resources :notes

  get 'welcome_pages/student'
  get 'welcome_pages/manager'
  
  get 'static_pages/home'

  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"} do
    delete 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end
end
