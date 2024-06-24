source 'https://rubygems.org'
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
ruby '3.1.2'

gem 'monster_id'
gem 'rails', '~> 7.1.3.2'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.5'

gem 'kaminari'
gem 'pager_api'
gem 'pagy'

gem 'rack-cors', :require => 'rack/cors'

gem 'fcm' #legacy...
gem 'fcmpush'

# gem 'wikiquote-api'

gem 'image_processing'
gem "mini_magick"

gem 'image_optim'
gem 'image_optim_pack'
gem 'sanitize'

gem 'slack-ruby-client'
gem 'eventmachine'
gem 'faye-websocket'

gem 'aws-sdk', '~> 3'

gem 'couchrest'

gem 'active_model_serializers', '~> 0.10.0'

gem 'carrierwave'
  
gem "fog-aws"

gem 'dotenv-rails', groups: [:development, :test]

gem 'rolify'

gem 'aasm'

gem 'paper_trail'

gem 'eth'

# generate a PDF version of the schedule for users with accessiblity needs
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
gem 'groupdate'
gem 'rubyzip'

# gem 'wkhtmltopdf-heroku', '2.12.6.0'

group :development, :test do
  gem 'byebug', platform: :mri
end
group :development do
  gem 'web-console', '>= 4.1.0'
  gem 'listen', '~> 3.3'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'bootstrap-sass'
gem 'devise'
gem 'high_voltage'
# gem 'mysql2', '~> 0.3.18'
gem 'pundit'
gem 'pg'

gem 'mailgun-ruby'

group :development do
  gem 'dotenv'
  gem 'better_errors'
  gem 'rails_layout'
  gem 'spring-commands-rspec'
end
group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rspec-rails'
  gem 'thin'
end
group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'selenium-webdriver'
end

gem 'acts_as_paranoid', '~> 0.9.0'
gem 'bootstrap-generators', '~> 3.3.4'

gem 'pry-rails', :group => :development

gem 'sha3'

gem 'telegram-bot-ruby'

gem "table_print"

gem 'sidekiq', '<8'

gem 'm3u8'

gem 'activerecord-import'

group :production do
  # gem 'puma'
end

gem 'httparty'

# gem 'soundcloud'

# gem 'yt', '~> 0.32.0'

gem 'net-http'

gem 'ssrf_filter', '1.0.8'