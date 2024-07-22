class AddWorkerToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :position, :string, limit: 30
    add_column :users, :rank, :integer
  end
end
