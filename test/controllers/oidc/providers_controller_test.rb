require "test_helper"

class OIDC::ProvidersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get oidc_providers_index_url

    assert_response :success
  end

  test "should get show" do
    get oidc_providers_show_url

    assert_response :success
  end
end
