class MessageSerializer < ActiveModel::Serializer
  attributes :id, :subject, :body, :pushed_state, :topic, :sent_at, :stream, :linked_model, :message_status, :app_version, :token_type_name, :send_at, :address
  type :message
  belongs_to :address

  def linked_model
  	if object.article_id
			object.article
  	elsif object.event_id
  		object.event
  	end
  end

  def token_type_name
    object.token_type.name rescue nil
  end

  def address
    if object.address_id
      Address.find(object.address_id.to_i).address
    end
  end
end