class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :transaction_id
      t.string :user_id
      t.string :status
      t.string :amount
      t.string :order_id

      t.timestamps
    end
  end
end
