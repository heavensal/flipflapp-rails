Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

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
    resources :invitations
    resources :notifications
  end

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post "users/sign_in", to: "users/sessions#create"
        delete "users/sign_out", to: "users/sessions#destroy"
        post "users", to: "users/registrations#create"
        post "users/password", to: "users/passwords#create"
        patch "users/password", to: "users/passwords#update"
        put "users/password", to: "users/passwords#update"
        post "users/confirmation", to: "users/confirmations#create"
      end

      get "me", to: "users#me"
      patch "me", to: "users#update"
      resources :users, only: [ :show ]

      resources :events, only: %i[index show create update destroy] do
        resources :event_teams, only: %i[index show update] do
          resources :event_participants, only: [ :index ]
        end
        resources :event_participants, only: %i[index create]
        scope module: :events do
          resources :invitations, only: %i[index create]
        end
      end
      resources :event_participants, only: [ :destroy ]

      get "friendships/search", to: "friendships#search"
      resources :friendships, only: [ :index, :create, :update, :destroy ]

      resources :notifications, only: [ :index, :destroy ] do
        patch :read, on: :member
        patch :read_all, on: :collection
      end
    end
  end
end
