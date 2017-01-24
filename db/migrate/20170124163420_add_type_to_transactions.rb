class AddTypeToTransactions < ActiveRecord::Migration
  def up
    add_column :transactions, :type, :string
    add_column :transactions, :refunded, :boolean
    add_column :transactions, :refunded_transaction_id, :string
  end

  def down
    remove_column :transactions, :type, :string
    remove_column :transactions, :refunded, :boolean
    remove_column :transactions, :refunded_transaction_id, :string
  end
end
