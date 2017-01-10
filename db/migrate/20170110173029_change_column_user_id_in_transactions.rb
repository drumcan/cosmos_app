class ChangeColumnUserIdInTransactions < ActiveRecord::Migration
  def up
    change_column :transactions, :user_id, :integer
  end

  def down
    change_column :transactions, :user_id, :string
  end
end
