class CreateITicktemplates < ActiveRecord::Migration
  def up
    create_table :i_ticktemplates do |t|
      t.string :name, :limit => 64
      t.belongs_to :app_issue, index: true, :null => true
      t.belongs_to :using_issue, index: true, :null => true
      t.boolean :deleted
      t.belongs_to :updated_by, :null => true, :null => true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_ticktemplates
  end
end
