class CreateIEntities < ActiveRecord::Migration
  def up
    create_table :i_entities do |t|
      t.string :name, :limit => 64
      t.string :description, :limit => 128, :null => true
      t.string :ipv4, :limit => 16, :null => true
      t.boolean :deleted
      t.belongs_to :updated_by, :null => true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_entities
  end
end

