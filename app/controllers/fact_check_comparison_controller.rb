class FactCheckComparisonController < ApplicationController
  require "nokodiff"
  require "nokogiri"

  include TokenHelper

  before_action :authenticate_user!, unless: :token_bypass?, only: :compare

  def compare
    @default_content = ""
    @request = Request.most_recent_for_source(source_app: params[:source_app], source_id: params[:source_id])
    raise ActiveRecord::RecordNotFound, "No request found" unless @request

    @current_content = @request.current_content.deep_symbolize_keys
    @previous_content = @request.previous_content&.deep_symbolize_keys || @current_content.deep_dup

    mark_current_content
    @differ = create_diff
    @article_title = @request.source_title
    @deadline = @request.deadline.to_date.to_s
    @draft_url = draft_origin_preview_url(@request)
    render "fact_check_comparison"
  end

private

  def mark_current_content
    # Both have a single content block, we can diff it directly
    if @current_content == 1 && @previous_content == 1
      return
    end

    # Else, content block matching
    mark_removed_in_current
    mark_added_in_current
  end

  # If the item doesn't exist in current, give it a blank
  # for accurate display of diff
  # Not needed for items that don't exist in previous as
  # current is the source of truth.
  def mark_removed_in_current
    current_part_ids = @current_content.keys

    current_content_array = Array(@current_content) # Allows index specific insertion

    @previous_content.each_with_index do |(previous_part_id, previous_part), index|
      next if current_part_ids.include?(previous_part_id)

      previous_part_heading = previous_part[:heading]
      insert_at = [index, current_content_array.length].min
      item_copy = { heading: "#{previous_part_heading} (REMOVED)", body: "" }
      current_content_array.insert(insert_at, [previous_part_id, item_copy])

      current_part_ids << previous_part_id
    end

    @current_content = current_content_array.to_h
  end

  def mark_added_in_current
    @current_content.each do |part_id, current_part|
      current_part_heading = current_part[:heading]

      @current_content[part_id][:heading] = "#{current_part_heading} (ADDED)" if @previous_content[part_id].blank?
    end
  end

  def create_diff
    diff_hash = {}

    @current_content.each do |part_id, current_part|
      current_part_heading = current_part[:heading]
      current_part_content = current_part[:body]

      previous_part_content = @previous_content.dig(part_id, :body)

      heading = @current_content.size == 1 ? nil : current_part_heading

      diff_hash[heading] = Nokodiff.diff(previous_part_content, current_part_content)
    end

    diff_hash
  end

  def token_bypass?
    current_request = Request.most_recent_for_source(source_app: bypass_params[:source_app], source_id: bypass_params[:source_id])
    return unless current_request

    valid_compare_preview_jwt?(bypass_params[:token], current_request)
  end

  def bypass_params
    params.permit(:source_app, :source_id, :token)
  end
end
