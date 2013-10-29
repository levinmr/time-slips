class ClientsController < ApplicationController
  def index
    @clients = Client.all.sort_by{ |c| c.name.downcase }
  end

  def show
    @client = Client.find(params[:id])   
  end

  def new
    @client = Client.new
  end

  def edit
    @client = Client.find(params[:id])
  end

  def create
    @client = Client.new(params[:client])

    if @client.save
      redirect_to( clients_path, :notice => "Client created successfully.")
    else
      flash[:error] = "Error creating Client"
      render :new
    end
  end

  def update
    @client = Client.find(params[:id])

    if @client.update_attributes(params[:client])
      redirect_to( clients_path, :notice => "Client updated.")
    else
      flash[:error] = "Error updating Client"
      render :edit
    end
  end

  def destroy
    @client= Client.find(params[:id])
    @client.destroy
    flash[:notice] = "Client deleted."
    redirect_to(clients_path)
  end
end
