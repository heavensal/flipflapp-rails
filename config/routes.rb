Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  #
  # Routes d'authentication
  authenticated :user do
    root to: "events#home", as: :authenticated_root
  end

  unauthenticated do
    root to: "pages#home", as: :unauthenticated_root
  end
  devise_for :users, controllers: {
    confirmations: "users/confirmations",
    registrations: "users/registrations"
  }
  get "me", to: "users#me", as: :me
  resources :users, only: [ :show ]
  patch "locale/:locale", to: "locales#update", as: :locale

  resources :events do
    resources :event_teams, only: [ :edit, :update ]
    resources :event_participants, only: [ :create ]
    scope module: :events do
      resources :invitations, only: [ :create ]
    end
  end
  resources :event_participants, only: [ :destroy ]
  resources :friendships, only: [ :index, :create, :update, :destroy ]
  get "friendships/search", to: "friendships#search", as: :search_friendships

  resources :notifications, only: [ :index, :destroy ] do
    patch :read, on: :member
    patch :read_all, on: :collection
  end
  get "list", to: "notifications#list", as: :notifications_list

  namespace :admin do
    root to: "dashboard#index"
    resources :users do
      post :send_password_reset, on: :member
    end
    resources :events
    resources :event_teams
    resources :event_participants
    resources :friendships
    resources :notifications
  end
end
