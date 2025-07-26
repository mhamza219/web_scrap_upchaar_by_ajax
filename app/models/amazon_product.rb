class AmazonProduct < ApplicationRecord
  belongs_to :amazon_url
  
  validates :amazon_url, presence: true
end 