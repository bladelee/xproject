FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "部门#{n}" }
    
    trait :with_parent do
      association :parent, factory: :department
    end
  end
end 