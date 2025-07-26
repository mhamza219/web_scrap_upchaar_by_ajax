class ProductDataService < BaseService
  def initialize(url, scraped_data)
    @url = url
    @scraped_data = scraped_data
  end

  def call
    return { error: 'Invalid data provided' } if @url.blank? || @scraped_data.blank?
    
    if @scraped_data[:error]
      Rails.logger.info "Skipping save due to error: #{@scraped_data[:error]}"
      return { error: @scraped_data[:error] }
    end

    save_product_data
  rescue => e
    Rails.logger.error "Database error: #{e.message}"
    { error: "Failed to save data: #{e.message}" }
  end

  private

  attr_reader :url, :scraped_data

  def save_product_data
    existing_url = AmazonUrl.find_by(url: url)
    
    if existing_url
      handle_existing_url(existing_url)
    else
      create_new_url_and_product
    end

    { success: true, message: 'Data saved successfully' }
  end

  def handle_existing_url(existing_url)
    latest_product = existing_url.amazon_products.order(created_at: :desc).first
    
    if latest_product && data_unchanged?(latest_product)
      Rails.logger.info "URL already exists with same data: #{url}"
      return { success: true, message: 'Data unchanged, no duplicate saved' }
    end
    
    # URL exists but data has changed, create new product record
    existing_url.amazon_products.create!(product_attributes)
  end

  def create_new_url_and_product
    amazon_url = AmazonUrl.create!(
      url: url,
      product_name: scraped_data[:name]
    )
    
    amazon_url.amazon_products.create!(product_attributes)
  end

  def product_attributes
    {
      name: scraped_data[:name],
      mrp: scraped_data[:mrp],
      actual_price: scraped_data[:price],
      discount: scraped_data[:discount],
      price: scraped_data[:price],
      tax: scraped_data[:tax]
    }
  end

  def data_unchanged?(existing_product)
    existing_product.name == scraped_data[:name] &&
    existing_product.mrp == scraped_data[:mrp] &&
    existing_product.actual_price == scraped_data[:price] &&
    existing_product.discount == scraped_data[:discount] &&
    existing_product.price == scraped_data[:price] &&
    existing_product.tax == scraped_data[:tax]
  end
end 