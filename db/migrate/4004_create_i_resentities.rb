class CreateIResentities < ActiveRecord::Migration
  def up
    create_table :i_resentities do |t|
      t.belongs_to :i_entity, index: true
      t.belongs_to :i_resource, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_resentities
  end
end
