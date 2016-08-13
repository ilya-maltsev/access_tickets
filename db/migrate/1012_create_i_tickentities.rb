
class CreateITickentities < ActiveRecord::Migration
  def change
    create_table :i_tickentities do |t|
      t.belongs_to :i_entity, index: true
      t.belongs_to :i_ticket, index: true
      t.timestamps
    end
  end
end
