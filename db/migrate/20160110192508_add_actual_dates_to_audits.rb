class AddActualDatesToAudits < ActiveRecord::Migration
  def change
  	add_column :audits, :actual_start, :datetime
    add_column :audits, :actual_end, :datetime
  end
end
