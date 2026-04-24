class CreateTeamPairings < ActiveRecord::Migration[8.1]
  def change
    create_table :team_pairings do |t|
      t.references :tournament, null: false, foreign_key: true
      t.string :espn_team_name, null: false
      t.references :golfer_a, null: false, foreign_key: { to_table: :golfers }
      t.references :golfer_b, null: false, foreign_key: { to_table: :golfers }

      t.timestamps
    end

    add_index :team_pairings, [:tournament_id, :espn_team_name], unique: true
  end
end
