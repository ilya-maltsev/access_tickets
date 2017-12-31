class CreateIResgranters < ActiveRecord::Migration
  def up
    create_table :i_resgranters do |t|
      t.belongs_to :user, index: true
      t.belongs_to :i_resource, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_resgranters
  end
end
