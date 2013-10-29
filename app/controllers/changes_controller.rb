class ChangesController < ApplicationController
  def index
    @changes = Change.all.sort_by{ |c| c.name.downcase }
  end

  def show
    @change = Change.find(params[:id])   
  end

  def new
    @change = Change.new
  end

  def edit
    @change = Change.find(params[:id])
  end

  def create
    @change = Change.new(params[:change])

    if @change.save
      redirect_to( changes_path, :notice => "Change created successfully.")
    else
      flash[:error] = "Error creating Change"
      render :new
    end
  end

  def update
    @change = Change.find(params[:id])

    if @change.update_attributes(params[:change])
      redirect_to( changes_path, :notice => "Change updated.")
    else
      flash[:error] = "Error updating Change"
      render :edit
    end
  end

  def destroy
    @change= Change.find(params[:id])
    @change.destroy
    flash[:notice] = "Change deleted."
    redirect_to(changes_path)
  end
end
