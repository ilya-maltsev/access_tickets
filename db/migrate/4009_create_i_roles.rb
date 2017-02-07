class CreateIRoles < ActiveRecord::Migration
  def up
    create_table :i_roles do |t|
      t.belongs_to :i_resource, index: true
      t.belongs_to :updated_by, :null => true
      t.string :name
      t.string :description, :null => true
      t.boolean :deleted
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_roles
  end
end
