class FactCheckComparisonController < ApplicationController
  require "nokodiff"
  require "date"

  def compare
    before = previous_content["body"]
    after = current_content["body"]
    @article_title = tmp_req.source_title
    @date = Date.current.to_s
    @differ = Nokodiff.diff(before, after)
    @draft_url = "/"
    render "fact_check_comparison"
  end

  def tmp_req
    Request.last
  end

  def previous_content
    tmp_req.previous_content
  end

  def current_content
    tmp_req.current_content
  end
end
