class CreateLines < ActiveRecord::Migration
  def up
    create_table :lines do |t|
      t.belongs_to :sheet
      t.date :date
      t.float :time
      t.text :description
      t.timestamps
    end
  end
  
  def down
    drop_table :lines
  end
end
