class AddBalanceToUsers < ActiveRecord::Migration
  def change
    add_column :users, :balance, :string
    add_column :users, :first_six, :string
    add_column :users, :last_four, :string
    add_column :users, :cart_type, :string
  end
end
