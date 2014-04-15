Fitplan::Application.routes.draw do
  # resources :sessions, only: [:new, :create, :destroy]
  root 'fitplan#index'
  post '/login_submit' => 'fitplan#login_submit'
  post '/signup_submit' => 'fitplan#signup_submit'
  post '/signout_submit' => 'fitplan#signout_submit'
  get  '/profile_form' => 'fitplan#profile_form'
  post '/profile_form/submit' => 'fitplan#profile_form_submit'
  get  '/profile' => 'fitplan#profile'
  post '/profile/add_food' => 'fitplan#add_food'
  post '/profile/add_food/get_calorie' => 'fitplan#get_calorie'
  post '/profile/add_food/get_calorie/add' => 'fitplan#add_food_submit'
  post '/profile/delete_food' => 'fitplan#delete_food'
  get '/profile/workout' => 'fitplan#workout'
  post '/profile/workout/get_recommended' => 'fitplan#get_recommended'
  post '/profile/workout/add_entry' => 'fitplan#add_workout_entry'
  post '/test' => 'fitplan#test'
  get '/progress' => 'fitplan#progress'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
