Rails.application.routes.draw do
  devise_for :users, only: [:sessions], controllers: {sessions: 'users/sessions'}

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get "quotes/:tag", to: "quotes#show", as: :quote
    end
  end

  require "sidekiq/web"
  require "sidekiq/cron/web"

  mount Sidekiq::Web => '/sidekiq'

end
