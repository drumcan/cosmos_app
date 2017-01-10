class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :payment_token
      t.string :remember_token
      t.string :password_digest

      t.timestamps
    end
  end
end
