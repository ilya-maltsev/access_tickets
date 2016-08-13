class CreateIResentities < ActiveRecord::Migration
  def change
    create_table :i_resentities do |t|
      t.belongs_to :i_entity, index: true
      t.belongs_to :i_resource, index: true
      t.timestamps
    end
  end
end
