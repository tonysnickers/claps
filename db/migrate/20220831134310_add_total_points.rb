class AddTotalPoints < ActiveRecord::Migration[7.0]
  def change
    add_column :groups, :total_points, :integer, default: 0
  end
end
