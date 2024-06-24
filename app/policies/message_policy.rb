class MessagePolicy
  class Scope
    attr_reader :current_user, :scope

    def initialize(current_user, scope)
      @current_user  = current_user
      @scope = scope
    end

    # super_admin users
      # access all 
    # admin users  
      # access Festivals they can access
    # otherwise 
      # access messages they have created
    def resolve
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
		@message = model
	end

	def index?
    true
	end

  # super admin or Festival admins can create   
	def create?
    @festival = Festival.find(@message.festival_id)
    current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
	end	

  # super admin or Festival admins can destroy 
	def destroy?
    @festival = Festival.find(@message.festival_id)
    current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
	end		

  # super admin or Festival admins can update 
	def update?
    @festival = Festival.find(@message.festival_id)
    current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
	end			

  # super admin or Festival admins can send_message   
	def send_message?
    @festival = Festival.find(@message.festival_id)
    current_user.has_role?('super_admin') or current_user.has_role?('admin', @festival)
	end
end
