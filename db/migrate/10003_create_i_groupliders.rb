class CreateIGroupliders < ActiveRecord::Migration
  def up
    create_table :i_groupliders do |t|
      t.belongs_to :user, index: true
      t.belongs_to :group, index: true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_groupliders
  end
end
