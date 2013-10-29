TimeSlips::Application.routes.draw do  
  resources :sheets

  resources :lines

  resources :changes
  
  resources :clients
  
  root :to => "sheets#index"
end
