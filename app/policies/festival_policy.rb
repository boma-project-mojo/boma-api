class FestivalPolicy

  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    def resolve
      # Festival admins should have have role with resource relationship
      # u.add_role(:admin, Festival.find(1))

      # super_admin users
        # access all 
      # otherwise 
        # access Festivals they can access
      if current_user.has_role?('super_admin')
        scope.all
      else
        scope.where(id: current_user.can_index_festivals)
      end
    end
  end

  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @festival = model
  end

  def show?
    true
  end

  def index?
    true
  end

  # super_admin users can create
  def create?
    @current_user.has_role?('super_admin')
  end

  # super_admin users or Festival admin users can update
  def update?
    @current_user.has_role?('super_admin') or @current_user.has_role?('admin', @festival)
  end

  def destroy?

  end

end