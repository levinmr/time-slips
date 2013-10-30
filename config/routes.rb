TimeSlips::Application.routes.draw do  
  resources :sheets do
    get :parse
  end

  resources :lines

  resources :changes
  
  resources :clients
  
  root :to => "sheets#index"
end
