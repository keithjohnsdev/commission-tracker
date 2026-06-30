require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get agency_dashboard_url(agencies(:one))
    assert_response :success
  end
end
