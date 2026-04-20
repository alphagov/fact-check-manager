class FactCheckComparisonController < ApplicationController
  require "nokodiff"

  def compare
    @request = Request.most_recent_for_source(source_app: params[:source_app], source_id: params[:source_id])
    raise ActiveRecord::RecordNotFound, "No request found" unless @request

    before = parse_html(@request.previous_content&.fetch("body", nil))
    after = parse_html(@request.current_content.fetch("body", nil))

    @differ = Nokodiff.diff(before, after)
    @article_title = @request.source_title
    @deadline = @request.deadline.to_date.to_s
    @draft_url = draft_origin_preview_url(@request)

    render "fact_check_comparison"
  end

private

  def parse_html(html_text)
    # TODO: Remove this when HTML is coming from API
    view_context.simple_format(html_text)
  end
end
