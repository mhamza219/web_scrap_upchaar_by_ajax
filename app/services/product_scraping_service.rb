require 'httparty'
require 'nokogiri'

class ProductScrapingService < BaseService
  def initialize(url)
    @url = url
    @domain = extract_domain(url)
  end

  def call
    return { error: 'Invalid URL provided' } if @url.blank?
    
    response = fetch_page
    return { error: 'Failed to fetch page' } unless response.success?
    
    doc = Nokogiri::HTML(response.body)
    scraped_data = scrape_by_domain(doc)
    
    if scraped_data.values.compact.any?
      scraped_data.merge(success: true)
    else
      { error: 'No product data found on this page' }
    end
  rescue => e
    Rails.logger.error "Scraping error for #{@url}: #{e.message}"
    { error: "Failed to scrape product: #{e.message}" }
  end

  private

  attr_reader :url, :domain

  def fetch_page
    HTTParty.get(url, headers: {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language' => 'en-US,en;q=0.5',
      'Accept-Encoding' => 'gzip, deflate',
      'Connection' => 'keep-alive',
    })
  end

  def extract_domain(url)
    uri = URI.parse(url)
    host = uri.host.downcase
    
    case host
    when /amazon/
      'amazon'
    when /flipkart/
      'flipkart'
    when /ebay/
      'ebay'
    else
      'generic'
    end
  rescue URI::InvalidURIError
    'generic'
  end

  def scrape_by_domain(doc)
    case domain
    when 'amazon'
      scrape_amazon(doc)
    when 'flipkart'
      scrape_flipkart(doc)
    when 'ebay'
      scrape_ebay(doc)
    else
      scrape_generic(doc)
    end
  end

  def scrape_amazon(doc)
    {
      name: doc.at_css('#productTitle')&.text&.strip,
      price: extract_amazon_price(doc),
      mrp: doc.at_css('.a-text-price .a-offscreen')&.text&.strip,
      discount: extract_amazon_discount(doc),
      tax: doc.at_css('#taxInclusiveMessage')&.text&.strip,
      source: 'Amazon'
    }
  end

  def scrape_flipkart(doc)
    {
      name: find_text(doc, ['h1[class*="title"]', '.product-title', 'h1']),
      price: find_text(doc, ['[class*="price"]', '.price', '.product-price']),
      mrp: find_text(doc, ['[class*="mrp"]', '.mrp', '.original-price']),
      discount: find_text(doc, ['[class*="discount"]', '.discount', '.savings']),
      tax: nil,
      source: 'Flipkart'
    }
  end

  def scrape_ebay(doc)
    {
      name: find_text(doc, ['h1[class*="title"]', '.product-title', 'h1']),
      price: find_text(doc, ['[class*="price"]', '.price', '.product-price']),
      mrp: nil,
      discount: nil,
      tax: nil,
      source: 'eBay'
    }
  end

  def scrape_generic(doc)
    {
      name: find_text(doc, ['h1', '.product-title', '.product-name', 'title']),
      price: find_text(doc, ['.price', '.product-price', '[class*="price"]']),
      mrp: find_text(doc, ['.mrp', '.original-price', '[class*="mrp"]']),
      discount: find_text(doc, ['.discount', '.savings', '[class*="discount"]']),
      tax: nil,
      source: 'Generic'
    }
  end

  def extract_amazon_price(doc)
    price = doc.at_css('.aok-offscreen')&.text&.strip ||
            doc.at_css('#priceblock_ourprice')&.text&.strip ||
            doc.at_css('#priceblock_dealprice')&.text&.strip ||
            doc.at_css('.a-price .a-offscreen')&.text&.strip

    if price.blank?
      symbol = doc.at_css('.a-price-symbol')&.text&.strip
      whole = doc.at_css('.a-price-whole')&.text&.strip
      price = "#{symbol}#{whole}" if symbol && whole
    end

    price
  end

  def extract_amazon_discount(doc)
    discount = doc.at_css('.savingsPercentage')&.text&.strip
    
    if discount.blank?
      offscreen_text = doc.at_css('.aok-offscreen')&.text&.strip
      if offscreen_text && offscreen_text.match(/(\d+\s*percent\s*savings)/i)
        discount = offscreen_text.match(/(\d+\s*percent\s*savings)/i)[1]
      end
    end

    discount
  end

  def find_text(doc, selectors)
    selectors.each do |selector|
      element = doc.at_css(selector)
      return element.text.strip if element && element.text.present?
    end
    nil
  end
end 