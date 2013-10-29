class CreateClients < ActiveRecord::Migration
  def up
    create_table :clients do |t|
      t.string :abbrev
      t.string :name
      t.timestamps
    end
    
    change_table :lines do |t|
      t.belongs_to :client
    end
  end
  
  def down
    drop_table :clients
    
    change_table :lines do |t|
      t.remove :client_id
    end
  end
end
