class UserMailerPreview < ActionMailer::Preview
  # We do not have confirmable enabled, but if we did, this is
  # how we could generate a preview:
  def invite_instructions
    UserMailer.invite(User.first, "faketoken", Festival.first)
  end
end