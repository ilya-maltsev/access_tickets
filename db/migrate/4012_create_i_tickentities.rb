class CreateITickentities < ActiveRecord::Migration
  def up
    create_table :i_tickentities do |t|
      t.belongs_to :i_entity, index: true
      t.belongs_to :i_ticket, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_tickentities
  end
end
