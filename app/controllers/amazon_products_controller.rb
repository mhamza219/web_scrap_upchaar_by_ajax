class AmazonProductsController < ApplicationController
  def index
    @amazon_urls = AmazonUrl.includes(:amazon_products).order(created_at: :desc)
  end

  def new
  end

  def create
    url = params[:url]
    
    if url.present?
      # Use the service layer to handle scraping and data persistence
      @result = ProductManagementService.call(url)
    else
      @result = { error: 'Please provide a valid product URL.' }
    end

    respond_to do |format|
      format.html { render :new }
      format.js { render :new }
    end
  end

  def destroy
    @amazon_url = AmazonUrl.find(params[:id])
    @amazon_url.destroy
    
    respond_to do |format|
      format.html { redirect_to amazon_products_path, notice: 'Data deleted successfully.' }
      format.js { render js: "window.location.href = '#{amazon_products_path}'" }
    end
  end
end 