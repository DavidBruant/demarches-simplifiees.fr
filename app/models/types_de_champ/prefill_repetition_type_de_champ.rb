class TypesDeChamp::PrefillRepetitionTypeDeChamp < TypesDeChamp::PrefillTypeDeChamp
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  def possible_values
    [
      I18n.t("views.prefill_descriptions.edit.possible_values.#{type_champ}_html"),
      subchamps_possible_values_list
    ].join("</br>").html_safe # rubocop:disable Rails/OutputSafety
  end

  def example_value
    [row_values_format, row_values_format].map { |row| row.to_s.gsub("=>", ":") }
  end

  alias_method :formatted_example_value, :example_value

  def to_assignable_attributes(champ, value)
    return [] unless value.is_a?(Array)

    value.map.with_index do |repetition, index|
      row = champ.rows[index] || champ.add_row(champ.dossier_revision)
      JSON.parse(repetition).map do |key, value|
        id = row.find { |champ| champ.libelle == key }&.id
        next unless id
        { id: id, value: value }
      end.compact
    rescue JSON::ParserError
    end.compact
  end

  private

  def too_many_possible_values?
    false
  end

  def subchamps_possible_values_list
    "<ul>" + prefillable_subchamps.map do |prefill_type_de_champ|
      "<li>#{prefill_type_de_champ.libelle}: #{prefill_type_de_champ.possible_values}</li>"
    end.join + "</ul>"
  end

  def row_values_format
    @row_example_value ||=
      prefillable_subchamps.map do |prefill_type_de_champ|
      [prefill_type_de_champ.libelle, prefill_type_de_champ.example_value.to_s]
    end.to_h
  end

  def prefillable_subchamps
    return [] unless active_revision_type_de_champ

    @prefillable_subchamps ||=
      TypesDeChamp::PrefillTypeDeChamp.wrap(active_revision_type_de_champ.revision_types_de_champ.map(&:type_de_champ).filter(&:prefillable?))
  end
end
