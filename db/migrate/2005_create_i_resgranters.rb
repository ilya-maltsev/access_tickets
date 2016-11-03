class CreateIResgranters < ActiveRecord::Migration
  def change
    create_table :i_resgranters do |t|
      t.belongs_to :user, index: true
      t.belongs_to :i_resource, index: true
      t.timestamps
    end
  end
end
