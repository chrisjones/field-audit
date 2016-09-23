class CreateAudit < ActiveRecord::Migration
  def change
  	create_table :audits do |t|
      t.string         :vendor
      t.string         :community
      t.string         :lot
      t.string         :task
      t.string         :builder
      t.datetime       :posted
 
      t.string         :ready
      t.string         :completed
      t.string         :clean
      t.string				 :quality
      t.string			   :started

      t.text           :note
      t.timestamps     null: false
    end
  end
end
