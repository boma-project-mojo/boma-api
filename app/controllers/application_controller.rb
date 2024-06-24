class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  private 

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(root_path)
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def format_error model
    errors = model.errors.map do |error|
      {
        "detail": "#{error.attribute.capitalize} #{error.message}",
        "source": {
          "pointer": "data/attributes/#{error.attribute}"
        }
      }
    end

    return errors
  end

end