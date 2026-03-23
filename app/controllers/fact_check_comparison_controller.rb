class FactCheckComparisonController < ApplicationController
  require "nokodiff"

  def compare
    session.delete(:fact_check_response) unless params[:back]
    request_item = retrieve_request_item
    before = parse_html(request_item.previous_content["body"])
    after = parse_html(request_item.current_content["body"])
    @article_title = request_item.source_title
    @deadline = request_item.deadline.to_date.to_s
    @differ = Nokodiff.diff(before, after)
    @draft_url = "/"

    setup_session(request_item)

    render "fact_check_comparison"
  end

private

  def retrieve_request_item
    Request.find_by(source_app: params[:source_app], source_id: params[:source_id])
  end

  def parse_html(html_text)
    # TODO: Remove this when HTML is coming from API
    view_context.simple_format(html_text)
  end

  def setup_session(request_item)
    session_object = session[:fact_check_response] ||= {}
    session_object[:request_id] ||= request_item.id
    session_object[:article_title] = @article_title
    session_object[:source_app] = params[:source_app]
    session_object[:source_id] = params[:source_id]
  end
end
