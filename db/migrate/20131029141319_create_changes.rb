class CreateChanges < ActiveRecord::Migration
  def up
    create_table :changes do |t|
      t.string :abbrev
      t.string :name
      t.timestamps
    end
  end
  
  def down
    drop_table :changes 
  end
end
