class AddLocationToAudits < ActiveRecord::Migration
  def change
  	add_column :audits, :location, :string
  end
end
