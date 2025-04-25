class CreateEmployees < ActiveRecord::Migration[7.1]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.references :department, foreign_key: true
      t.string :position
      t.integer :age
      
      t.timestamps
    end
  end
end 