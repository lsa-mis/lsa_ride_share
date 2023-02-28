Rails.application.routes.draw do
  resources :admin_accesses
  resources :config_questions
  resources :vehicle_reports
  resources :reservations
  resources :cars
  resources :students
  resources :sites
  resources :programs
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
