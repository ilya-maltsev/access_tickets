class CreateITickets < ActiveRecord::Migration
  def up
    create_table :i_tickets do |t|
      t.belongs_to :issue, index: true, :null => true
      t.belongs_to :user, index: true, :null => true
      t.belongs_to :i_resource, index: true
      t.belongs_to :i_role
      t.belongs_to :i_ticktemplate, :null => true
      t.string :description, :limit => 128, :null => true
      t.string :r_uid, :limit => 10, :null => true
      t.string :t_uid, :limit => 10, :null => true
      t.column :s_date, :date, :null => true
      t.column :e_date, :date, :null => true
      t.column :f_date, :date, :null => true
      t.boolean :deleted
      t.belongs_to :verified_by, :null => true
      t.timestamp :verified_at, :null => true
      t.belongs_to :approved_by,:null => true
      t.timestamp :approved_at, :null => true
      t.belongs_to :created_by, :null => true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_tickets
  end
end
