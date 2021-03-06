Glsamaker::Application.routes.draw do

  match 'bug/:id'                     => 'bug#bug',             :as => :bug
  match 'bug/:id/history'             => 'bug#history',         :as => :bughistory

  match 'cve/list.:format'            => 'cve#list',            :as => :cve
  
  match 'search/results'              => 'search#results',      :as => :search
  
  match 'admin'                       => 'admin/index#index'

  resources :glsas, :controller => 'glsa' do
    resources :comments
    resources :bugs

    get  'requests',          :on => :collection
    get  'drafts'  ,          :on => :collection
    get  'archive',           :on => :collection
    post 'archive',           :on => :collection

    get  'diff',              :on => :member
    post 'diff',              :on => :member
    get  'download',          :on => :member
    get  'import_references', :on => :member
    post 'import_references', :on => :member
    get  'prepare_release',   :on => :member
    post 'prepare_release',   :on => :member
    post 'release',           :on => :member
    get  'update_cache',      :on => :member
    get  'finalize_release',  :on => :member
    post 'finalize_release',  :on => :member
    get  'toggle_reviewready', :on => :member
  end
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  
  namespace :admin do
    resources :users
    resources :templates
  end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'index#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  match ':controller(/:action(/:id(.:format)))'
  # 
end
