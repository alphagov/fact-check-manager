namespace :fact_check do
  desc "Revoke preview link for given request ids"
  task :revoke_preview_link_by_request_ids, [:request_ids] => :environment do |_t, args|
    request_ids = args[:request_ids].split(",")

    request_ids.each do |id|
      request = Request.find_by(id: id)

      request.auth_bypass_id = SecureRandom.uuid
      request.save!
    end
  end

  desc "Revoke preview link for given source ids"
  task :revoke_preview_links_by_source_ids, [:source_ids] => :environment do |_t, args|
    request_source_ids = args[:source_ids].split(",")
    request_source_ids.each do |id|
      request = Request.find_by(source_id: id)

      request.auth_bypass_id = SecureRandom.uuid
      request.save!
    end
  end
end
