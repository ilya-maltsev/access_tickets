class CreateIResources < ActiveRecord::Migration
  def change
    create_table :i_resources do |t|
      t.string :name
      t.string :description
      t.boolean :has_ip
      t.boolean :has_entities
      t.boolean :deleted
      t.belongs_to :updated_by
      t.timestamps
    end
  end
end
