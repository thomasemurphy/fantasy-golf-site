class CreateTournamentResults < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_results do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :golfer, null: false, foreign_key: true
      t.integer :position
      t.bigint :earnings_cents, default: 0
      t.boolean :made_cut, null: false, default: false

      t.timestamps
    end

    add_index :tournament_results, [ :tournament_id, :golfer_id ], unique: true
  end
end
