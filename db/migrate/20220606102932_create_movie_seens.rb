class CreateMovieSeens < ActiveRecord::Migration[7.0]
  def change
    create_table :movie_seens do |t|
      t.references :movie, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end