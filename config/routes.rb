Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # auth
      post "auth/sign_in", to: "sessions#create"
      delete "auth/sign_out", to: "sessions#destroy"
      post "auth/sign_up", to: "registrations#create"

      # user
      get "users/me", to: "users#show"
      patch "users/me", to: "users#update"
      patch "users/me/email", to: "users#update_email"
      patch "users/me/password", to: "users#update_password"
    end
  end
end
