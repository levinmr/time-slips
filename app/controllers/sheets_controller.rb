class SheetsController < ApplicationController
  def index
    @sheets = Sheet.all.sort_by{ |s| s.name.downcase }
    @sheet = Sheet.new
  end

  def show
    @sheet = Sheet.find(params[:id])   
  end

  def new
    @sheet = Sheet.new
  end

  def edit
    @sheet = Sheet.find(params[:id])
  end

  def create
    @sheet = Sheet.new(params[:sheet])
    
    if @sheet.save
      redirect_to( sheets_path, :notice => "Sheet created successfully.")
    else
      @sheets = Sheet.all.sort_by{ |s| s.name.downcase }
      render :index
    end
  end

  def update
    @sheet = Sheet.find(params[:id])

    if @sheet.update_attributes(params[:sheet])
      redirect_to( sheets_path, :notice => "Sheet updated.")
    else
      flash[:error] = "Error updating Sheet"
      render :edit
    end
  end

  def destroy
    @sheet= Sheet.find(params[:id])
    @sheet.destroy
    flash[:notice] = "Sheet deleted."
    redirect_to(sheets_path)
  end
  
  def parse
    @sheet = Sheet.find(params[:sheet_id])
    @sheet.parse_file
    @sheet = Sheet.find(params[:sheet_id])
    @sheet.combine_lines
    @sheet = Sheet.find(params[:sheet_id])
    
    flash[:notice] = "Data imported from file"
    render :show
  end
end
