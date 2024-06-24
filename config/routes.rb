Rails.application.routes.draw do
  namespace :data_api do
    namespace :v1 do
      post 'authenticate', to: 'users#authenticate'
      resources :articles, only: ["index", "create"]
      resources :tags, only: ["index", "create"]
      resources :venues, only: ["index", "create"]
      resources :productions, only: ["index", "create"]
      resources :events, only: ["index", "create"]
    end
  end

  root to: 'visitors#index'
  devise_for :users
  resources :users

  get 'claim_token', to: 'tokens#claim_token'

  namespace :feed do
    namespace :v1 do
      get 'festivals/:festival_id/feed.json', to: 'feed#feed'
      get 'festivals/:festival_id/csv_dump.csv', to: 'feed#csv_dump'
      get 'festivals/:festival_id/bash_dump.sh', to: 'feed#bash_dump'
    end
  end

  namespace :api do
    namespace :v1 do
    	get 'messages', to: 'messages#index'
    	post 'suggestions', to: 'suggestions#create'
      post 'validate-token', to: 'tokens#validate'
      get 'get-tokens-by-address', to: 'tokens#index'
      post 'redeem-token', to: 'tokens#redeem'

      get 'validate-other', to: 'tokens#validate_other'

      post 'create-or-update-address', to: 'addresses#create_or_update_address'

      post 'create_address_answer', to: 'address_answers#create'

      post 'respond_to_survey', to: 'surveys#create'

      post 'events', to: 'events#create'
      post 'venues', to: 'venues#create'

      post 'articles', to: 'articles#create'

      post 'report-activity', to: 'activities#report_activity'

      post 'report_activity_for_all_festivals', to: 'activities#report_activity_for_all_festivals'

      get 'venues/search', to: 'venues#search'
      get 'venues/reverse_search', to: 'venues#reverse_search'
    end
  end

  namespace :admin_api do
    namespace :v1 do
      post 'users/sign-in', to: 'auth#session_sign_in'
      post 'users/forgotten-password', to: 'auth#forgotten_password'
      post 'users/reset-password', to: 'auth#reset_password'
      post 'users/claim-invite', to: 'auth#claim_invite'

      post 'users/send-invite', to: 'users#send_invite'
      post 'messages/send-message', to: 'messages#send_message'

      resources :addresses, only: ["show"]
    end
  end

  namespace :admin_api do
    namespace :v1 do
      resources :surveys, only: ["show", "create", "update", "destroy"]
      post 'articles/request_presigned_url', to: 'articles#request_presigned_url'
      resources :organisations do
        resources :articles, only: ["index", "create", "update", "destroy"]
        resources :tags, only: ["index"]
      end
      resources :festivals do
        post 'set-roles/venues', to: 'set_roles#venues'
        resources :productions
        resources :events
        resources :venues
        # resources :tags
        # resources :pages               
        resources :tags
        resources :users
        resources :pages
        resources :messages 
        resources :token_types
        resources :articles, only: ["index", "create", "update", "destroy"]
        resources :activities, only: ["index"]
        get 'activities/stats_for_main_chart', to: 'activities#stats_for_main_chart'
        get 'activities/stats_by_model_type_for_chart', to: 'activities#stats_by_model_type_for_chart'
        get 'activities/stat_types_by_tag_for_chart', to: 'activities#stat_types_by_tag_for_chart'
        get 'activities/stats_for_users', to: 'activities#stats_for_users'
        get 'activities/notifications_and_publishing', to: 'activities#notifications_and_publishing'
        get :as_xml, to: 'festivals#as_xml'
        get :as_pdf, to: 'festivals#as_pdf'
        get :as_csv, to: 'festivals#as_csv'
      end
    end
  end  
end
