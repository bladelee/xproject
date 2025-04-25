FactoryBot.define do
  factory :employee do
    sequence(:name) { |n| "员工#{n}" }
    position { "工程师" }
    association :department
  end
end 