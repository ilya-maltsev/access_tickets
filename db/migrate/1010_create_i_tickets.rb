class CreateITickets < ActiveRecord::Migration
  def change
    create_table :i_tickets do |t|
      t.belongs_to :issue, index: true
      t.belongs_to :user, index: true
      t.belongs_to :i_resource, index: true
      t.belongs_to :i_role
      t.belongs_to :i_ticktemplate
      t.string :description, :limit => 128
      t.string :r_uid, :limit => 10
      t.string :t_uid, :limit => 10
      t.column :s_date, :date
      t.column :e_date, :date
      t.column :f_date, :date
      t.boolean :deleted
      t.belongs_to :verified_by, :null => true
      t.timestamp :verified_at, :null => true
      t.belongs_to :approved_by,:null => true
      t.timestamp :approved_at, :null => true
      t.belongs_to :created_by
      t.timestamps
    end
  end
end
