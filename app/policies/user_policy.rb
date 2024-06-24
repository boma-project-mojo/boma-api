class UserPolicy

  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    def resolve
      # super_admin can see all
      # admin users can see all for the Festivals they can access
      # other users can see all for the Venues they have access to
      if current_user.has_role?('super_admin') or current_user.has_role?('admin', :any)
        festival_venues = Role.where(resource_type: "AppData::Venue").where(resource_id: @current_user.current_festival.venues).pluck(:resource_id)
        scope.joins(:roles).where("roles.resource_type" => "AppData::Venue").where("roles.resource_id IN (?)", festival_venues).or(scope.joins(:roles).where("roles.resource_type" => "Festival").where("roles.resource_id" => current_user.current_festival))
      end
    end
  end

  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @user = model
  end

  def index?      
    true
  end

  # super_admin and Festival admins for any festival can show
  def show?
    @current_user.has_role?('super_admin') or @current_user.has_role?('admin', :any)
  end

  # super_admin and Festival admins for any festival can create
  def create?
    @current_user.has_role?('super_admin') or @current_user.has_role?('admin', :any)
  end

  # super_admin and Festival admins for any festival can update
  def update?
    @current_user.has_role?('super_admin') or @current_user.has_role?('admin', :any)
  end

  # super_admin and Festival admins for any festival can destroy
  def destroy?
    return false if @current_user == @user
    @current_user.has_role?('super_admin') or @current_user.has_role?('admin', :any)
  end

end