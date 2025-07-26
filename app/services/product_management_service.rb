class ProductManagementService < BaseService
  def initialize(url)
    @url = url
  end

  def call
    return { error: 'URL is required' } if @url.blank?

    # Step 1: Scrape the product data
    scraping_result = ProductScrapingService.call(@url)
    
    if scraping_result[:error]
      return { error: scraping_result[:error] }
    end

    # Step 2: Save the data to database
    data_result = ProductDataService.call(@url, scraping_result)
    
    if data_result[:error]
      return { error: data_result[:error] }
    end

    # Return the scraped data with success status
    scraping_result.merge(
      success: true,
      saved: true,
      message: data_result[:message]
    )
  rescue => e
    Rails.logger.error "Product management error: #{e.message}"
    { error: "Failed to process product: #{e.message}" }
  end

  private

  attr_reader :url
end 