require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "should get auth page" do
    get auth_url

    assert_response :success
  end
end