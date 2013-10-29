class CreateSheets < ActiveRecord::Migration
  def up
    create_table :sheets do |t|
      t.string :name
      t.string :file
      t.timestamps
    end
  end
  
  def down
    drop_table :sheets
  end
end
