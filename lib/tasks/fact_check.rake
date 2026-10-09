namespace :fact_check do
  desc "Revoke preview links for the given request ids"
  task :revoke_preview_link_by_request_ids, [:request_ids] => :environment do |_t, args|
    # Rake splits "task[id1,id2]" on commas, so each id is a separate argument
    request_ids = args.to_a
    requests = Request.where(id: request_ids)

    requests.each { |request| request.update!(auth_bypass_id: SecureRandom.uuid) }
    puts "Revoked preview links for #{requests.size} request(s)"

    missing_ids = request_ids - requests.map { |request| request.id.to_s }
    abort "No requests found for request ids: #{missing_ids.join(', ')}" if missing_ids.any?
  end

  desc "Revoke preview links for every request for a source app's source ids, for example fact_check:revoke_preview_links_by_source_ids[publisher,id1,id2]"
  task :revoke_preview_links_by_source_ids, [:source_app] => :environment do |_t, args|
    source_app = args[:source_app]
    source_ids = args.extras
    requests = Request.where(source_app:, source_id: source_ids)

    requests.each { |request| request.update!(auth_bypass_id: SecureRandom.uuid) }
    puts "Revoked preview links for #{requests.size} request(s)"

    missing_ids = source_ids - requests.map(&:source_id)
    abort "No requests found for source app #{source_app} and source ids: #{missing_ids.join(', ')}" if missing_ids.any?
  end
end
