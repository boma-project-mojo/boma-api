class AppData::ArticlePolicy
  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    def resolve
      # super_admin users 
        # to view everyting
      # admin users
        # who 'can_index_organisation' 
          # allow records that are in scope of the Organisation(s) they have access tp
        # who 'can_index_festivals'
          # allow records that are in scope of the Festival(s) they have access tp
      if current_user.has_role?('super_admin')
        scope.all
      elsif current_user.has_role?('admin', :any)
        # If has admin role for Organisation show all 
        if current_user.can_index_organisations.count > 0
          scope.where(organisation_id: current_user.can_index_organisations)
        elsif current_user.can_index_festivals.count > 0
          scope.where(festival_id: current_user.can_index_festivals)
        end
      end
    end
  end

  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @article = model
  end

  def index?
    true
  end

  def show?
    true
  end

  # allow super_admin and users with admin role for an Organisation or Festival to create
  def create?
    if @article.organisation_id
      @organisation = Organisation.find(@article.organisation_id)
      current_user.has_role?('super_admin') or current_user.has_role?('admin', @organisation)
    elsif @article.festival_id
      @festival = Festival.find(@article.festival_id)
      current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
    end
  end

  # allow super_admin and users with admin role for an Organisation or Festival to update
  def update?
    if @article.organisation_id
      @organisation = Organisation.find(@article.organisation_id)
      current_user.has_role?('super_admin') or current_user.has_role?('admin', @organisation)
    elsif @article.festival_id
      @festival = Festival.find(@article.festival_id)
      current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
    end
  end

  # allow super_admin and users with admin role for an Organisation or Festival to destroy
  def destroy?
    if @article.organisation_id
      @organisation = Festival.find(@article.organisation_id)
      current_user.has_role?('super_admin') or current_user.has_role?('admin', @organisation)
    elsif @article.festival_id
      @festival = Festival.find(@article.festival_id)
      current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
    end
  end

end