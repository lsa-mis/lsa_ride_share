Rails.application.routes.draw do
  resources :faculty_surveys do
    resources :config_questions, module: :faculty_surveys
  end

  resources :site_contacts

  resources :units

  get 'unit_preference/:name', to: 'unit_preferences#delete_preference', as: :delete_preference
  get 'unit_preferences/unit_prefs', to: 'unit_preferences#unit_prefs', as: :unit_prefs
  post 'unit_preferences/unit_prefs/', to: 'unit_preferences#save_unit_prefs'
  resources :unit_preferences

  resources :terms
  resources :admin_accesses
  get '/vehicle_reports/:reports_ids', to: 'vehicle_reports#index', as: 'vehicle_reports'
  resources :vehicle_reports
  resources :reservations
  resources :cars do
    resources :notes, module: :cars
  end
  resources :students
  resources :sites do
    resources :notes, module: :sites
  end
  resources :program_managers
  resources :programs do
    resources :cars, module: :programs
  end
  resources :programs do
    resources :sites, module: :programs
  end
  resources :programs do
    resources :program_managers, module: :programs
  end
  resources :programs do
    resources :config_questions, module: :programs
  end
  resources :programs do
    resources :students, module: :programs
  end

  get '/programs/students/add_students/:program_id', to: 'programs/students#add_students', as: :add_students
  get '/programs/students/update_student_list/:program_id', to: 'programs/students#update_student_list', as: :update_student_list, defaults: { format: :turbo_stream }
  get '/programs/students/update_mvr_status/:program_id', to: 'programs/students#update_mvr_status', as: :update_mvr_status, defaults: { format: :turbo_stream }
  get '/programs/students/canvas_results/:program_id', to: 'programs/students#canvas_results', as: :canvas_results, defaults: { format: :turbo_stream }

  get 'programs/duplicate/:id', to: 'programs#duplicate', as: :duplicate
  delete 'programs/remove_car/:id/:car_id', to: 'programs#remove_car', as: :remove_car
  delete 'programs/remove_site/:id/:site_id', to: 'programs#remove_site', as: :remove_site
  delete 'programs/remove_program_manager/:id/:program_manager_id', to: 'programs#remove_program_manager', as: :remove_program_manager
  delete 'programs/remove_config_question/:id/:config_question_id', to: 'programs#remove_config_question', as: :remove_config_question
  get 'programs/add_config_questions/:id/', to: 'programs#add_config_questions', as: :add_config_questions
  get 'programs/program_data/:id/', to: 'programs#program_data', as: :program_data

  get 'application/delete_file_attachment/:id', to: 'application#delete_file_attachment', as: :delete_file

  resources :program_managers
  resources :notes
  
  get 'static_pages/home'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root to: "static_pages#home"

  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"} do
    delete 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end
end
