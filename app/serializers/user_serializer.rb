class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :aasm_state, :reset_password_sent_at, :is_festival_admin, :is_super_admin, :roles
  type :user

  def is_festival_admin
    object.can_edit_festivals.count > 0
  end

  def is_super_admin
    object.has_role?(:super_admin)
  end

  def roles
    object.roles
  end
end
