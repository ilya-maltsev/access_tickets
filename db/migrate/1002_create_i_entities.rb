class CreateIEntities < ActiveRecord::Migration
  def change
    create_table :i_entities do |t|
      #t.belongs_to :i_groupentity, index: true
      #t.belongs_to :i_resentity, index: true
      t.string :name, :limit => 64
      t.string :description, :limit => 128
      t.string :ipv4, :limit => 16
      t.boolean :deleted
      t.belongs_to :updated_by
      t.timestamps
    end
  end
end
