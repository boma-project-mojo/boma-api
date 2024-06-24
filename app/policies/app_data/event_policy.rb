class AppData::EventPolicy

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
        scope.where(venue_id: current_user.can_edit_venues)
      end
    end
  end

  attr_reader :current_user, :model

  def initialize(current_user, model)
    @current_user = current_user
    @event = model
  end

  def show?
    true
  end

  def index?
    true
  end

  # user can create events
  # if super_admin or admin or
  # if they are assigned as editor to the venue and event is of type draft
  def create?
    @festival = Festival.find(@event.festival_id)

    @current_user.has_role?('super_admin') or
    @current_user.has_role?('admin', @festival) or
    @event.venue.nil? or
    (current_user.has_role?("editor", @event.venue) and @event.draft?)
  end
  
  # user can update events
  # if admin or super admin
  # or if they are assigned as editor to the venue and event is of type draft
  def update?
    @festival = Festival.find(@event.festival_id)
    if @current_user.has_role?('super_admin') or @current_user.has_role?('admin', @festival)
      true
    elsif current_user.has_role?("editor", @event.venue) and @event.draft?
      if !@event.requires_production?
        # object doesn't require a production, allow update
        can_update = true
      else
        if @event.production
          if @event.production.draft?
            # object is unlocked, allow update
            can_update = true
          else
            # object is locked or published, restrict update
            can_update = false
          end
        else
          # object doesn't have a production, allow update
          can_update = true
        end
      end
    end
  end

  def destroy?
    #user can destroy events 
      #if admin 
      #or if they are assigned as editor to the venue and event is of type draft
    @festival = Festival.find(@event.festival_id)

    @current_user.has_role?('super_admin') or
    @current_user.has_role?('admin', @festival) or
    (current_user.has_role?("editor", @event.venue) and @event.draft?)
  end

end