class CreateIResugroups < ActiveRecord::Migration
  def up
    create_table :i_resugroups do |t|
      t.belongs_to :group, index: true
      t.belongs_to :i_resource, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_resugroups
  end
end
