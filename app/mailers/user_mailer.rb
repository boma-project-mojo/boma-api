class UserMailer < ApplicationMailer
  def invite(user,token,festival)
    # attachments.inline['green_bus_co_logo.gif'] = File.read(Rails.root.join("app", "assets", "images", "green_bus_co_logo.gif"))
    @user = user
    @token = token
    @festival = festival
    mail(to: @user.email, subject: "You have been invited to edit #{@festival.name}")
  end
end
