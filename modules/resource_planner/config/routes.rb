Rails.application.routes.draw do
  resources :resource_planners,
            controller: "resource_planner/resource_planner",
            only: %i[create] do
    collection do
      get "/", to: "resource_planner/resource_planner#overview"
      get "/new", to: "resource_planner/resource_planner#new"
      get "/upsale", to: "resource_planner/resource_planner#upsale", as: :upsale
    end
  end

  scope "projects/:project_id", as: "project" do
    resources :resource_planners,
              controller: "resource_planner/resource_planner",
              only: %i[index destroy],
              as: :resource_planners do
      collection do
        get "/upsale", to: "resource_planner/resource_planner#upsale", as: :upsale
        get "/new", to: "resource_planner/resource_planner#show", as: :new
      end

      member do
        get "(/*state)" => "resource_planner/resource_planner#show", as: ""
      end
    end
  end
end
