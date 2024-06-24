class AddChainToTokenTypes < ActiveRecord::Migration[7.0]
  def change
    add_column :token_types, :chain, :string

    # Shambala 2019 2
    TokenType.find(2).update! chain: "ethereum"
    # Publisher 3
    TokenType.find(3).update! chain: "ethereum"
    # Shambala 2018 1
    TokenType.find(1).update! chain: "ethereum"
    # Ambassador 4
    TokenType.find(4).update! chain: "ethereum"
    # Shambala 2020 5
    TokenType.find(5).update! chain: "ethereum"
    # Shambala Validator 6
    TokenType.find(6).update! chain: "ethereum"
    # Shambala 2022 8
    TokenType.find(8).update! chain: "gnosis"
    # Shambala Star 9
    TokenType.find(9).update! chain: "gnosis"
    # Shambino 2021 7
    TokenType.find(7).update! chain: "ethereum"
    # Shambala 2022 Testers 10
    TokenType.find(10).update! chain: "gnosis"
  end
end
