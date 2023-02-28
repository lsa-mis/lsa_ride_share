Rails.application.routes.draw do
  resources :terms
  resources :admin_accesses
  resources :config_questions
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
  get 'programs/duplicate/:id', to: 'programs#duplicate', as: :duplicate
  get 'programs/remove_car/:id/:car_id', to: 'programs#remove_car', as: :remove_car
  get 'programs/remove_site/:id/:site_id', to: 'programs#remove_site', as: :remove_site
  get 'programs/remove_program_manager/:id/:program_manager_id', to: 'programs#remove_program_manager', as: :remove_program_manager

  resources :program_managers
  devise_for :users
  get 'static_pages/home'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root to: "static_pages#home"
end
