Rails.application.routes.draw do
  resources :terms
  resources :admin_accesses
  resources :vehicle_reports
  resources :reservations
  resources :cars
  resources :students
  resources :sites
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
  get 'programs/duplicate/:id', to: 'programs#duplicate', as: :duplicate
  delete 'programs/remove_car/:id/:car_id', to: 'programs#remove_car', as: :remove_car
  delete 'programs/remove_site/:id/:site_id', to: 'programs#remove_site', as: :remove_site
  delete 'programs/remove_program_manager/:id/:program_manager_id', to: 'programs#remove_program_manager', as: :remove_program_manager
  delete 'programs/remove_config_question/:id/:config_question_id', to: 'programs#remove_config_question', as: :remove_config_question
  get 'programs/add_config_questions/:id/', to: 'programs#add_config_questions', as: :add_config_questions
  get 'programs/program_data/:id/', to: 'programs#program_data', as: :program_data

  resources :program_managers
  get 'static_pages/home'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root to: "static_pages#home"

  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"} do
    delete 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end
end
