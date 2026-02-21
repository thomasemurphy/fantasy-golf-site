class CreateGolfers < ActiveRecord::Migration[8.1]
  def change
    create_table :golfers do |t|
      t.string :name, null: false
      t.string :sportsdata_id

      t.timestamps
    end

    add_index :golfers, :sportsdata_id, unique: true
    add_index :golfers, :name
  end
end
