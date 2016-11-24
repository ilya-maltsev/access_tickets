class CreateIResources < ActiveRecord::Migration
  def change
    create_table :i_resources do |t|
      t.string :name
      t.string :description, :null => true
      t.boolean :has_ip, :null => true
      t.boolean :has_entities, :null => true
      t.boolean :deleted
      t.belongs_to :updated_by, :null => true
      t.timestamps null: false
    end
  end
end
