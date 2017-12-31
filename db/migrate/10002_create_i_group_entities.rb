class CreateIGroupEntities < ActiveRecord::Migration
  def up
    create_table :i_group_entities do |t|
      t.belongs_to :i_resource, index: true, :null => true
      t.belongs_to :i_entity_id, index: true, :null => true
      t.string :name, :limit => 64
      t.belongs_to :updated_by, :null => true
      t.boolean :deleted
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_group_entities
  end
end
