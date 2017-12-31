class CreateIRetimeaccesses < ActiveRecord::Migration
  def up
    create_table :i_retimeaccesses do |t|
      t.belongs_to :i_access, index: true, :null => true
      t.string :r_uid, :limit => 10, :null => true
      t.column :old_e_date, :date , :null => true
      t.column :r_date, :date , :null => true
      t.belongs_to :r_verified_by, :null => true
      t.timestamp :r_verified_at, :null => true
      t.belongs_to :r_approved_by, :null => true
      t.timestamp :r_approved_at, :null => true
      t.belongs_to :retime_issue, index: true
      t.boolean :deleted
      t.belongs_to :created_by, :null => true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_retimeaccesses
  end
end
