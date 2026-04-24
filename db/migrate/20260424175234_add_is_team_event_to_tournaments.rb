class AddIsTeamEventToTournaments < ActiveRecord::Migration[8.1]
  def change
    add_column :tournaments, :is_team_event, :boolean, default: false, null: false
  end
end
