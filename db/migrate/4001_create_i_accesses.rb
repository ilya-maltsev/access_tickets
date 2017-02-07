class CreateIAccesses < ActiveRecord::Migration
  def up
    create_table :i_accesses do |t|
      t.belongs_to :i_ticket, index: true
      t.belongs_to :i_entity, index: true
      t.belongs_to :granted_by, :null => true
      t.timestamp :granted_at, :null => true
      t.belongs_to :confirmed_by, :null => true
      t.timestamp :confirmed_at, :null => true
      t.belongs_to :revoked_by, :null => true
      t.belongs_to :rev_issue, index: true
      t.timestamp :revoked_at, :null => true
      t.belongs_to :deactivated_by, :null => true
      t.timestamp :deactivated_at, :null => true
      t.boolean :deleted
      t.belongs_to :r_created_by, :null => true
      t.timestamps null: false
    end
  end

  def down
    drop_table :i_accesses
  end
end
