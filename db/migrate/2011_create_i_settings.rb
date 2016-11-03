class CreateISettings < ActiveRecord::Migration
  def change
    create_table :i_settings do |t|
      t.string :param, :limit => 256
      t.string :value, :limit => 1024
      t.boolean :deleted
      t.belongs_to :updated_by, :null => true
      t.timestamps
    end
  end
end
