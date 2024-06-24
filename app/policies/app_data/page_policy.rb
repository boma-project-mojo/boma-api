class AppData::PagePolicy
  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    def resolve
      # super_admin users 
        # to access everyting
      # admin users
        # who 'can_index_festivals'
          # allow records that are in scope of the Festival(s) they have access to
      # otherwise
        # allow records that the current user 'can_edit_venues' for
      if current_user.has_role?('super_admin')
        scope.all
      elsif current_user.has_role?('admin', :any)
        scope.where(festival_id: current_user.can_index_festivals)
      else
        scope.where(created_by: current_user.id)
      end
    end
  end

  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @page = model
  end

  def index?
    true
  end

  def show?
    true
  end

  # super admin or Festival admins can create 
  def create?
    @festival = Festival.find(@page.festival_id)
    current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
  end

  # super admin or Festival admins can update 
  def update?
    @festival = Festival.find(@page.festival_id)
    current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
  end

  # super admin or Festival admins can destroy 
  def destroy?
    @festival = Festival.find(@page.festival_id)
    current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
  end

end