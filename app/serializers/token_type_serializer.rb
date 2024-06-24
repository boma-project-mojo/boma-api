class TokenTypeSerializer < ActiveModel::Serializer
  attributes :id, :name, :total_tokens
  type :token_type

  def total_tokens
    object.tokens.mined.count
  end
end