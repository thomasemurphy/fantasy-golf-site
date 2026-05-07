class AddVenueToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :course_name, :string
    add_column :tournaments, :city, :string
    add_column :tournaments, :state, :string
  end
end
