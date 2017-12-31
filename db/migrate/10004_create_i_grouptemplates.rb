class CreateIGrouptemplates < ActiveRecord::Migration
  def up
    create_table :i_grouptemplates do |t|
      t.belongs_to :i_ticktemplate, index: true
      t.belongs_to :group, index: true
      t.boolean :deleted
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_grouptemplates
  end
end
