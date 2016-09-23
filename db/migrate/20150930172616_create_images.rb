class CreateImages < ActiveRecord::Migration
  def change
  	create_table :images do |t|
      t.belongs_to		 :audit, index: true
      t.string         :file
      t.string         :filename
      t.timestamps      null: false
    end
  end
end
