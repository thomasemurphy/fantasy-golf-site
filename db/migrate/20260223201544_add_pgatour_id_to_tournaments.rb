class AddPgatourIdToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :pgatour_id, :string
  end
end
