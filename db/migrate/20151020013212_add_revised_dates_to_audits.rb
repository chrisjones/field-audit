class AddRevisedDatesToAudits < ActiveRecord::Migration
  def change
    add_column :audits, :revised_start, :datetime
    add_column :audits, :revised_end, :datetime
  end
end
