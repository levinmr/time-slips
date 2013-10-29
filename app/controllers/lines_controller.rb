class LinesController < ApplicationController
  def index
    @lines = Line.all.sort_by{ |l| l.name.downcase }
  end

  def show
    @line = Line.find(params[:id])   
  end

  def new
    @line = Line.new
  end

  def edit
    @line = Line.find(params[:id])
  end

  def create
    @line = Line.new(params[:line])

    if @line.save
      redirect_to( lines_path, :notice => "Line created successfully.")
    else
      flash[:error] = "Error creating Line"
      render :new
    end
  end

  def update
    @line = Line.find(params[:id])

    if @line.update_attributes(params[:line])
      redirect_to( lines_path, :notice => "Line updated.")
    else
      flash[:error] = "Error updating Line"
      render :edit
    end
  end

  def destroy
    @line= Line.find(params[:id])
    @line.destroy
    flash[:notice] = "Line deleted."
    redirect_to(lines_path)
  end
end
