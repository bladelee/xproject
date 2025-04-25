class CreateEmployeeProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :employee_projects do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :employee_projects, [:employee_id, :project_id], unique: true
  end
end 