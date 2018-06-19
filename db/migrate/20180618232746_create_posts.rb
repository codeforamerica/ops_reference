class CreatePosts < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.timestamps
      t.string :name, null: false
      t.boolean :processed, null: false, default: false

      t.index :created_at
    end
  end
end
