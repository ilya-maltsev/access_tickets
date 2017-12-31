class CreateIResowners < ActiveRecord::Migration
  def up
    create_table :i_resowners do |t|
      t.belongs_to :user, index: true
      t.belongs_to :i_resource, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_resowners
  end
end
