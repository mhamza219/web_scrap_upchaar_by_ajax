class AmazonUrl < ApplicationRecord
  has_many :amazon_products, dependent: :destroy
  
  validates :url, presence: true, uniqueness: true
  validates :url, format: { with: URI::regexp(%w[http https]), message: "must be a valid URL" }
end 