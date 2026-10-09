parts = [
  { id: "part-1",
    heading: "Part 1 example",
    current_body: "<h2>Title</h2><p>Test paragraph goes here</p>",
    current_markdown_body: "## Title \n\n Test paragraph goes here",
    previous_body: "<h2>New title</h2><p>Changed paragraph goes here</p>",
    previous_markdown_body: "## New title \n\n Changed paragraph goes here",
  },
  { id: "part-2",
    heading: "Part 2 title",
    current_body: "<h2>Heading</h2><p>This is some <b>content</b></p>",
    current_markdown_body: "## Heading \n\n This is some **content**",
    previous_body: "<h2>Changed heading</h2><p>This is some <b>text</b> on this page</p>",
    previous_markdown_body: "## Changed heading \n\n This is some **text** on this page",
  }
]

scenarios = [
  {source_id: "one-part-content-only", part_count: 1, markdown:false, previous:false },
  {source_id: "one-part-with-markdown", part_count: 1, markdown:true, previous:false },
  {source_id: "two-part-content-only", part_count: 2, markdown:false, previous:false },
  {source_id: "two-part-with-markdown", part_count: 2, markdown:true, previous:false },
  {source_id: "one-part-comparison-content-only", part_count: 1, markdown:false, previous:true },
  {source_id: "one-part-comparison-with-markdown", part_count: 1, markdown:true, previous:true },
  {source_id: "two-part-comparison-content-only", part_count: 2, markdown:false, previous:true },
  {source_id: "two-part-comparison-with-markdown", part_count: 2, markdown:true, previous:true },
]

scenarios.each do |scenario|
  selected = parts.first(scenario[:part_count])
  source_id = scenario[:source_id]

  Request.find_or_create_by!(source_app: "test", source_id: source_id) do |request|
    request.source_id = source_id
    request.source_app = "test"
    request.source_title = source_id.humanize
    request.source_url = "https://example.com/#{source_id}"
    request.requester_name = "Test user"
    request.requester_email = "test.user@gov.uk"
    request.status = "new"
    request.deadline = 30.days.from_now
    request.reason_for_change = "Updated #{selected.map { |p| p[:heading].downcase }.to_sentence} wording"

    request.current_content = selected.to_h do |part|
      [part[:id], {"heading" => part[:heading], "body" => part[:current_body]}]
    end

    if scenario[:markdown]
      request.current_markdown = selected.to_h do |part|
        [part[:id], {"heading" => part[:heading], "body" => part[:current_markdown_body]}]
      end
    end

    if scenario[:previous]
      request.previous_content = selected.to_h do |part|
        [part[:id], {"heading" => part[:heading], "body" => part[:previous_body]}]
      end

      if scenario[:markdown]
        request.previous_markdown = selected.to_h do |part|
          [part[:id], {"heading" => part[:heading], "body" => part[:previous_markdown_body]}]
        end
      end

    end
  end
end