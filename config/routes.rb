Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
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
    # omniauth_callbacks: "users/omniauth_callbacks",
    confirmations: "users/confirmations",
    registrations: "users/registrations",
    passwords: "users/passwords",
    unlocks: "users/unlocks",
    sessions: "users/sessions"
  }
  get "me", to: "users#me", as: :me
  resources :users, only: [ :show ]

  resources :beta_testers

  resources :events do
    resources :event_teams, only: [ :edit, :update ]
    resources :event_participants, only: [ :create ]
    scope module: :events do
      resources :invitations, only: [ :create ]
    end
  end
  resources :event_participants, only: [ :destroy ]
  resources :friendships, only: [ :index, :create, :update, :destroy ]

  resources :notifications, only: [ :index ]
  get "list", to: "notifications#list", as: :notifications_list
end
