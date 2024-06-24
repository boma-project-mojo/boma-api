# spec/mailers/previews/devise_mailer_preview.rb

class DeviseMailerPreview < ActionMailer::Preview
  # We do not have confirmable enabled, but if we did, this is
  # how we could generate a preview:
  # def invite_instructions
  #   Devise::Mailer.invite_instructions(User.first, "faketoken", Festival.first)
  # end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(User.first, Devise.friendly_token)
  end

  def unlock_instructions
    Devise::Mailer.unlock_instructions(User.first, Devise.friendly_token)
  end

  def email_changed
    Devise::Mailer.email_changed(User.first)
  end

  def password_changed
    Devise::Mailer.password_change(User.first)
  end
end