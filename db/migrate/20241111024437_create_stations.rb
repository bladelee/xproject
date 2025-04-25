class CreateStations < ActiveRecord::Migration[7.1]
  def change
    create_table :stations do |t|
      t.string :name

      t.datetime :created_at
      t.datetime :updated_at
    end

  end
end
