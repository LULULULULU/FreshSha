Rails.application.routes.draw do
  root "welcome#about"
  
  get '/signup', to: "registrations#new"
  post '/signup', to: "registrations#create"

  get 'login', to: "sessions#new"
  post '/login', to: "sessions#create" 
  delete '/logout', to: "sessions#destroy"

  get 'users/:id', to: "users#show", as: "profile"

  # Skills
  post '/skill/sit', to: "messages#sit"
  post '/skill/shuffle', to: "messages#shuffle"
  post '/skill/use', to: "messages#skill"

  resources :chatrooms, param: :slug
  resources :messages
  
  # Serve websocket cable requests in-process
  mount ActionCable.server => '/cable'
end
