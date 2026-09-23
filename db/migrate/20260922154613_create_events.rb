class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :billetto_id, null: false
      t.string :title, null: false
      t.text :description
      t.string :image_url
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end
      add_index :events, :billetto_id, unique: true
  end
end
