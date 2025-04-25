class AddStationToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :station_id, :integer
    add_index :users, :station_id
    add_foreign_key :users, :stations
  end
end 