require "rails_helper"
require "rake"

RSpec.describe "RakeTaskTests", type: :request do
  describe "When revoking preview access for SMEs via rake task" do
    before(:each) do
      @test_request = FactoryBot.create(:request)
      @test_request_2 = FactoryBot.create(:request)
    end

    it "Resets for one item by request id with revoke_preview_link_by_request_ids" do
      Rake::Task["fact_check:revoke_preview_link_by_request_ids"].reenable

      pre_processed_bypass_id = @test_request.auth_bypass_id

      Rake::Task["fact_check:revoke_preview_link_by_request_ids"].invoke(@test_request.id.to_s)
      @test_request.reload

      expect(pre_processed_bypass_id).not_to eq(@test_request.auth_bypass_id)
    end

    it "Resets for multiple items by request id with revoke_auth_bypass_ids" do
      Rake::Task["fact_check:revoke_preview_link_by_request_ids"].reenable

      pre_processed_bypass_id = @test_request.auth_bypass_id
      pre_processed_bypass_id_2 = @test_request_2.auth_bypass_id

      Rake::Task["fact_check:revoke_preview_link_by_request_ids"].invoke(@test_request.id.to_s, @test_request_2.id.to_s)
      @test_request.reload
      @test_request_2.reload

      expect(pre_processed_bypass_id).not_to eq(@test_request.auth_bypass_id)
      expect(pre_processed_bypass_id_2).not_to eq(@test_request_2.auth_bypass_id)
    end

    it "Resets for one item by request id with revoke_preview_links_by_source_ids" do
      Rake::Task["fact_check:revoke_preview_links_by_source_ids"].reenable

      pre_processed_bypass_id = @test_request.auth_bypass_id

      Rake::Task["fact_check:revoke_preview_links_by_source_ids"].invoke(@test_request.source_id.to_s)
      @test_request.reload

      expect(pre_processed_bypass_id).not_to eq(@test_request.auth_bypass_id)
    end

    it "Resets an item by source id with revoke_auth_bypass_ids_by_source" do
      Rake::Task["fact_check:revoke_preview_links_by_source_ids"].reenable

      pre_processed_bypass_id = @test_request.auth_bypass_id
      pre_processed_bypass_id_2 = @test_request_2.auth_bypass_id

      Rake::Task["fact_check:revoke_preview_links_by_source_ids"].invoke(@test_request.source_id, @test_request_2.source_id)
      @test_request.reload
      @test_request_2.reload

      expect(pre_processed_bypass_id).not_to eq(@test_request.auth_bypass_id)
      expect(pre_processed_bypass_id_2).not_to eq(@test_request_2.auth_bypass_id)
    end

    it "Resets every request for a source id that has been sent for fact check more than once" do
      Rake::Task["fact_check:revoke_preview_links_by_source_ids"].reenable
      resent_request = FactoryBot.create(:request, source_id: @test_request.source_id)

      expect { Rake::Task["fact_check:revoke_preview_links_by_source_ids"].invoke(@test_request.source_id) }
        .to change { @test_request.reload.auth_bypass_id }
        .and(change { resent_request.reload.auth_bypass_id })
    end

    it "Resets the requests it finds, then exits listing the ids it cannot find" do
      Rake::Task["fact_check:revoke_preview_link_by_request_ids"].reenable

      expect { Rake::Task["fact_check:revoke_preview_link_by_request_ids"].invoke(@test_request.id.to_s, "0") }
        .to change { @test_request.reload.auth_bypass_id }
        .and raise_error(SystemExit, "No requests found for request ids: 0")
    end
  end
end
