require "spec_helper"

RSpec.describe "Empty query filters", :js do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }
  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:filters) { Components::WorkPackages::Filters.new }

  before do
    login_as(user)
    work_package
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  # Tests for regression #23739
  it "allows to delete the last query filter" do
    # Open filter menu
    filters.expect_filter_count(1)
    filters.open

    # Remove only filter
    filters.remove_filter(:status)

    wp_table.expect_work_package_listed(work_package)

    wp_table.expect_no_toaster(type: :error)
    filters.expect_filter_count(0)
  end
end
