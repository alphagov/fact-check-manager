module FormattedDiffHelpers
  def verify_static_elements
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(I18n.t("fact_check_comparison.heading"))
    expect(response.body).to include(I18n.t("fact_check_comparison.respond_by"))
    expect(response.body).to include(I18n.t("fact_check_comparison.respond_to_button"))
    expect(response.body).to include(I18n.t("fact_check_comparison.preview_heading"))
    expect(response.body).to include(I18n.t("fact_check_comparison.preview_link"))
    expect(response.body).to include(I18n.t("fact_check_comparison.guidance_heading"))
    expect(response.body).to include(I18n.t("fact_check_comparison.guidance_deleted"))
    expect(response.body).to include(I18n.t("fact_check_comparison.guidance_added"))
    expect(response.body).to include(I18n.t("fact_check_comparison.guidance_link"))
  end

  def verify_ins(parsed, expected)
    parsed[:ins].each do |diff|
      expect(diff).to include("Added content")
    end

    expect(parsed[:ins].map { |text| text.gsub("Added content", "").strip }).to eq(expected)

    expected.each do |element|
      expect(parsed[:del]).not_to include(element)
    end
  end

  def verify_del(parsed, expected)
    parsed[:del].each do |diff|
      expect(diff).to include("Removed content")
    end

    expect(parsed[:del].map { |text| text.gsub("Removed content", "").strip }).to eq(expected)

    expected.each do |element|
      expect(parsed[:ins]).not_to include(element)
    end
  end

  def verify_unchanged(parsed, expected)
    expected.each do |element|
      expect(parsed[:diff]).to include(element)
      expect(parsed[:del]).not_to include(element)
      expect(parsed[:ins]).not_to include(element)
    end
  end

  def verify_headings_order(parsed, expected)
    expect(parsed[:heading]).to eq(expected)
  end
end
