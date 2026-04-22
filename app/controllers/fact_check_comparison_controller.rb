class FactCheckComparisonController < ApplicationController
  require "nokodiff"
  require "nokogiri"

  def compare
    @default_content = ""
    @request = Request.most_recent_for_source(source_app: params[:source_app], source_id: params[:source_id])
    raise ActiveRecord::RecordNotFound, "No request found" unless @request

    @differ = create_diff(setup_content_pairs)
    @article_title = @request.source_title
    @deadline = @request.deadline.to_date.to_s
    @draft_url = draft_origin_preview_url(@request)

    render "fact_check_comparison"
  end

private

  def setup_content_pairs
    if @request.previous_content.blank?
      @request.previous_content = @request.current_content.deep_dup
    end

    if @request.current_content.size == 1 && @request.previous_content.size == 1
      return @request.current_content
    end

    mark_removed_in_current(@request.previous_content, @request.current_content)
  end

  # If the item doesn't exist in current, give it a blank
  # for accurate display of diff
  # Not needed for items that don't exist in previous as
  # current is the source of truth.
  def mark_removed_in_current(previous_content, current_content)
    current_ids = current_content.map(&:first).to_set

    current_content = Array(current_content) # Allows index specific insertion

    previous_content.each_with_index do |item, index|
      part_id = item.first
      item_copy = item.deep_dup

      next if current_ids.include?(part_id)

      insert_at = [index, current_content.length].min
      item_copy.last.transform_values! { "" }
      current_content.insert(insert_at, item_copy)

      current_ids.add(part_id)
    end

    current_content.to_h
  end

  def create_diff(current_content)
    diff_hash = {}

    current_content.each do |pair_id, pair_hash|
      heading = visible_heading = pair_hash.keys.first
      current = pair_hash[heading]
      previous = @request.previous_content.fetch(pair_id, "")
      previous_key = previous == "" ? heading : previous.keys.first

      if current_content.size == 1
        visible_heading = nil
      elsif previous.blank?
        visible_heading = "#{heading} (ADDED)"
      elsif current.blank?
        visible_heading = "#{heading} (REMOVED)"
      end

      diff_hash[visible_heading] = Nokodiff.diff(previous[previous_key], current)
    end

    diff_hash
  end
end
