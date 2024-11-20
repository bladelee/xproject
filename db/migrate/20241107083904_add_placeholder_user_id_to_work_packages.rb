class AddPlaceholderUserIdToWorkPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :work_packages, :placeholder_user_id, :bigint
  end
end
