class RemoveUniqueConstraintFromPicksUserGolfer < ActiveRecord::Migration[8.1]
  def change
    # BMW Championship (week 27) is the last tournament of the pool; the
    # poolrunner's spreadsheet has a handful of legitimate golfer reuses
    # (source of truth for this final week per admin decision). Drop the
    # hard uniqueness constraint but keep the index for lookups.
    remove_index :picks, [:user_id, :golfer_id], unique: true, name: "index_picks_on_user_id_and_golfer_id"
    add_index :picks, [:user_id, :golfer_id], name: "index_picks_on_user_id_and_golfer_id"
  end
end
