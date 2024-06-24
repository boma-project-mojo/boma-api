class AppData::ProductionPolicy
  
  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    # super_admin users 
      # to access everyting
    # admin users
      # who 'can_index_festivals'
        # allow records that are in scope of the Festival(s) they have access to
    # otherwise
      # allow records that are in scope of the Festival(s) they have access to
    def resolve
      if current_user.has_role?('super_admin')
        scope.all
      elsif current_user.has_role?('admin', :any)
        scope.where(festival_id: current_user.can_index_festivals)
      else
        scope.where(festival_id: current_user.can_index_festivals)
      end
    end
  end

  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @production = model
  end

  def index?
    true
  end

  def show?
    true
  end

  # allow super_admin or 
  # users with admin role for a Festival or
  # those assigned as editor to the venue and production is state :draft 
  # to edit
  def create?
    @festival = Festival.find(@production.festival_id)

    @current_user.has_role?('super_admin') or
    @current_user.has_role?('admin', @festival) or
    (@current_user.can_edit_venues.length > 0 and @production.draft?)
  end

  # allow super_admin or 
  # users with admin role for a Festival or
  # those assigned as editor to the venue and production is state :draft 
  # to update
  def update?
    @festival = Festival.find(@production.festival_id)

    @current_user.has_role?('super_admin') or
    @current_user.has_role?('admin', @festival) or
    (
      @current_user.can_edit_venues.length > 0 and 
      @production.draft?
    )
  end

  # allow super_admin or 
  # users with admin role for a Festival or
  # those assigned as editor to the venue and production is state :draft 
  # to destroy
  def destroy?
    @festival = Festival.find(@production.festival_id)

    @current_user.has_role?('super_admin') or
    @current_user.has_role?('admin', @festival) or
    (@current_user.can_edit_venues.length > 0 and @production.draft?)
  end

end