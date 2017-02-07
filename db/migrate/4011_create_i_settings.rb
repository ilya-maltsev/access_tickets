class CreateISettings < ActiveRecord::Migration
  def up
    create_table :i_settings do |t|
      t.string :param, :limit => 256
      t.string :value, :limit => 1024
      t.boolean :deleted
      t.belongs_to :updated_by, :null => true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_settings
  end
end
