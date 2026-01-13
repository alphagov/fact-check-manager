class FactCheckComparisonController < ApplicationController
  require "nokodiff"
  require "date"

  def compare
    before = previous_content
    after = current_content
    @article_title = "Title"
    @date = Date.current.to_s
    @differ = Nokodiff.diff(before, after)
    @draft_url = "/"
    render "fact_check_comparison"
  end

  def previous_content
    "<div>This is a line with no changes</div> <div>This line will change</div>"
  end

  def current_content
    "<div>This is a line with no changes</div> <div>This line has some changes</div>"
  end
end
