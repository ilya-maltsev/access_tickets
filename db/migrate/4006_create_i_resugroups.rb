class CreateIResugroups < ActiveRecord::Migration
  def change
    create_table :i_resugroups do |t|
      t.belongs_to :group, index: true
      t.belongs_to :i_resource, index: true
      t.timestamps null: false
    end
  end
end
