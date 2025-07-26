class CreateAmazonProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :amazon_products do |t|
      t.references :amazon_url, null: false, foreign_key: true
      t.string :name
      t.string :mrp
      t.string :actual_price
      t.string :discount
      t.string :price
      t.string :tax
      t.timestamps
    end
  end
end 