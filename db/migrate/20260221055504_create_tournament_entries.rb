class CreateTournamentEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :tournament_entries do |t|
      t.references :tournament, null: false, foreign_key: true
      t.references :golfer, null: false, foreign_key: true

      t.timestamps
    end

    add_index :tournament_entries, [ :tournament_id, :golfer_id ], unique: true
  end
end
