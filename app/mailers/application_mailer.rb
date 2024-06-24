class ApplicationMailer < ActionMailer::Base
  default from: ENV['from_email_address']
  layout 'mailer'
end
