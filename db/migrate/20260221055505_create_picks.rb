class CreatePicks < ActiveRecord::Migration[8.1]
  def change
    create_table :picks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tournament, null: false, foreign_key: true
      t.references :golfer, null: false, foreign_key: true
      t.boolean :is_double_down, null: false, default: false
      t.boolean :auto_assigned, null: false, default: false
      t.bigint :earnings_cents
      t.boolean :made_cut

      t.timestamps
    end

    # One pick per user per tournament
    add_index :picks, [ :user_id, :tournament_id ], unique: true
    # Each golfer can only be picked once per user per season (enforced in app layer)
    add_index :picks, [ :user_id, :golfer_id ], unique: true
  end
end
