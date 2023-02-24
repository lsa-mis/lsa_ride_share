Rails.application.routes.draw do
  resources :terms
  resources :admin_accesses
  resources :config_questions
  resources :vehicle_reports
  resources :reservations
  resources :cars
  resources :students
  resources :sites
  resources :programs do
    resources :cars, module: :programs
  end
  get 'programs/duplicate/:id', to: 'programs#duplicate', as: :duplicate
  resources :program_managers
  devise_for :users
  get 'static_pages/home'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  root to: "static_pages#home"
end
