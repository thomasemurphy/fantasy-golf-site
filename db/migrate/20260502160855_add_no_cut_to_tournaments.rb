class AddNoCutToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :no_cut, :boolean, default: false, null: false
  end
end
