class AddColumnToWorkPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :work_packages, :station_id, :bigint
    add_column :work_package_journals, :station_id, :bigint

  end
end
