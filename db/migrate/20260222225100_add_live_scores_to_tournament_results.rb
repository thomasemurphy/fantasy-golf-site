class AddLiveScoresToTournamentResults < ActiveRecord::Migration[8.1]
  def change
    add_column :tournament_results, :current_position, :integer
    add_column :tournament_results, :current_position_display, :string
    add_column :tournament_results, :current_score_to_par, :integer
    add_column :tournament_results, :current_thru, :string
    add_column :tournament_results, :current_round, :integer
    add_column :tournament_results, :current_earnings_cents, :bigint
  end
end
