class CreateAmazonUrls < ActiveRecord::Migration[7.1]
  def change
    create_table :amazon_urls do |t|
      t.string :url, null: false
      t.string :product_name
      t.timestamps
    end
    
    add_index :amazon_urls, :url, unique: true
  end
end 