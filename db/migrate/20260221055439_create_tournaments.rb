class CreateTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :tournaments do |t|
      t.string :name, null: false
      t.date :start_date
      t.date :end_date
      t.bigint :purse_cents, default: 0
      t.string :tournament_type, null: false, default: "regular"
      t.string :status, null: false, default: "upcoming"
      t.string :sportsdata_id
      t.integer :week_number
      t.datetime :picks_locked_at

      t.timestamps
    end

    add_index :tournaments, :sportsdata_id, unique: true
    add_index :tournaments, :week_number, unique: true
    add_index :tournaments, :start_date
  end
end
