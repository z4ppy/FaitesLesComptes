Faitesvoscomptes::Application.routes.draw do

  

  get "bottom/credit"
  get "bottom/contact"

  get "bottom/apropos"

  get "modallines/create"

  resource :session

  

  # namespace COMPTA



  namespace :compta do
    resources :users do
      resources :rooms
    end

    # TODO simplifier car on n'utilise que l'action show
    resources :rooms
    resources :organisms do
      resources :periods do
        member do
          get 'change' # pour changer d'exercice
        end
      end
    end
    resources :books do
      resources :writings do
        member do
          post :lock
        end
        collection do
          post :all_lock
        end
      end
    end
    resources :periods do
      
      resource :balance
      resource :nomenclature
      resources :accounts
      resource :listing
      resource :general_book
      resource :general_ledger
      resources :sheets do
        collection do
          get :bilans
          get :resultats
          get :benevolats
          get :detail
          get :liasse
        end
      end
      resources :selections do
        member do
          post :lock
        end
      end
      
    end
    
    

    resources :accounts  
  end
  # fin du namespace COMPTA


  
  ##################### namespace ADMIN ##############################"
   namespace 'admin' do


    get "versions/new"
    post "versions/migrate_each"

    resources :users do
      resources :rooms
    end

    resources :rooms do
      member do
        get 'new_archive'
      end
    end
    
    resource :restore do
      member do
        post 'rebuild'
      end
    end
    resources :organisms do

      resource :nomenclature

      resources :archives
      resources :books
      resources :income_books
      resources :outcome_books
      
    
      resources :destinations
      resources :bank_accounts do
        resources :bank_extracts, :only=>[:index, :edit, :destroy] do
          member do
            get 'unlock'
          end
        end
      end
      resources :cashes do
        resources :cash_controls, only: [:index, :destroy]
      end
      resources :periods do
        member do
          get 'change'
          get 'select_plan'
          get 'close'
          post 'create_plan'
        end
        resources :lines do
          member do
            post 'lock'
          end
        end
        resources :natures do
          collection do
            post 'reorder' # pour permettre le tri par javascript
          end
        end
        
      end
    end
    resources :periods do
      resources :natures do
        member do
          post :link_nature, :unlink_nature
        end
      end
      resources :accounts do
        collection do
          get :mapping
        end
      end
    end
  end  # FIN DE ADMIN

  

  # DEBUTde la zone public

  resources :users do
    resources :rooms
  end

  # TODO simplifier car on n'utilise que l'action show
  resources :rooms

  resources :transfers # on se passe maintenant de organism
  # et aussi de book car automatiquement en book OD

  resources :organisms , :only=> [:index, :show] do
    resources :periods, :only=> [:index, :show] do
      member do
        get 'change' # pour changer d'exercice
      end
      resources :natures, only: :index do
        collection do
          get 'stats' # statistiques de recettes et dépenses par natures
        end
      end
    end

    resources :check_deposits, :only=>:new # pour faire des remises de chèques
    #    resources :income_books
    #    resources :outcome_books
    
    
    resources :bank_accounts do
      resources :check_deposits
    end

  end
  
  resources :bank_accounts do
    resources :bank_extracts do
      member do
        post 'lock'
      end
    end
  end

  # match ':controller/:action/:id/with_user/:user_id'
  resources :bank_extracts do
    resources :modallines     
    resources :bank_extract_lines do
      
      collection do
        get 'pointage'
        post 'reorder'
        post 'ajoute'
        
      end
      member do
        post 'degroup'
        post 'regroup'
        post 'remove'
        post 'insert'
        
        
      end
    end
  end

    
  resources :books do
    resources :writings
    resources :in_out_writings
    resources :lines do
      member do
        post 'lock' # pour la requete ajax
      end
    end
    
  end

  resources :income_books do
    resources :lines
    resources :in_out_writings
  end
  resources :outcome_books do
    resources :lines
    resources :in_out_writings
  end
  resources :cashes, :only=> [:show] do
    resources :cash_controls do
      member do
        put 'lock'
      end
    end
    resources :cash_lines
  end

  resources :transfers

 

  root to: 'sessions#new'
  

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

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
