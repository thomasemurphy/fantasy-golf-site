Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

  root "standings#index"

  resources :picks, only: %i[index create destroy]
  resources :standings, only: [:index]
  post "standings/refresh", to: "standings#refresh", as: :refresh_standings

  namespace :admin do
    root "users#index"
    resources :users, only: %i[index show update] do
      member do
        patch :approve
        patch :toggle_paid
      end
    end
    resources :tournaments, only: %i[index show update] do
      member do
        post :sync_field
        post :sync_results
        post :sync_live
        get  :earnings
        post :update_earnings
        post :sync_earnings
      end
    end
    resources :picks, only: %i[index show]
  end

  mount Sidekiq::Web => "/sidekiq" if defined?(Sidekiq::Web)

  get "up" => "rails/health#show", as: :rails_health_check
end
