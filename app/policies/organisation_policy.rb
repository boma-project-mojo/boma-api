class OrganisationPolicy

  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    def resolve
      # Festival admins should have have role with resource relationship
      # u.add_role(:admin, Organisation.find(1))

      if current_user.has_role?('super_admin')
        scope.all
      else
        can_index_orgs = Festival.where(id: current_user.can_index_festivals).collect(&:organisation_id).uniq
        scope.where(id: can_index_orgs)
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

  # super admin can create 
  def create?
    @current_user.has_role?('super_admin')
  end

  # super admin can update 
  def update?
    @current_user.has_role?('super_admin')
  end

  def destroy?

  end

end