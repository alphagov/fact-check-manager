module ApiHelpers
  def stub_fact_check_response_posts(success: true)
    response = if success
                 GdsApi::Response.new(code: 200)
               else
                 GdsApi::HTTPErrorResponse.new(code: 422)
               end
    allow(Services.publisher_api).to receive(:post_fact_check_response).and_return(response)
  end
end
