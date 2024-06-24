class DataApi::ArticlePolicy < AppData::ArticlePolicy

  # User permissions for API access
  # > @user = User.find_by_email('pete@1up.digital') 
  # > @user.add_role(:api_write, @organisation) 
  # > @user.add_role(:api_write, @festival) 

  # users with api_write role for Festival or Organisation can create 
  def create?
    if @article.organisation_id
      @organisation = Organisation.find(@article.organisation_id)
      current_user.has_role?('api_write', @organisation)
    elsif @article.festival_id
      @festival = Festival.find(@article.festival_id)
      current_user.has_role?('api_write', @festival.organisation)
    end
  end
end