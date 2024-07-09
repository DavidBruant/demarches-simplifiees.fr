class ExportItem
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::SanitizeHelper

  attr_reader :template, :enabled, :stable_id

  def initialize(item)
    @template = item['template']
    @enabled = item['enabled']
    @stable_id = item['stable_id']
  end

  def to_h
    {
      'template' => @template,
      'enabled' => @enabled,
      'stable_id' => @stable_id
    }
  end

  def template_json = template.to_json

  def enabled? = enabled

  def readable_template
    leaves.map do
      if _1['type'] == 'text'
        tag.span(_1['text'])
      else
        tag.span(_1['attrs']['label'], class: 'fr-tag fr-tag--sm')
      end
    end.join.then { sanitize(_1) }
  end

  def mention_ids
    leaves
      .filter { |leaf| leaf['type'] == 'mention' }
      .map { |mention| mention['attrs']['id'] }
      .filter(&:present?)
  end

  def texts
    leaves
      .filter { |leaf| leaf['type'] == 'text' }
      .map { |text| text['text'] }
      .filter(&:present?)
  end

  private

  def leaves
    return [] if !template.is_a?(Hash)

    first_content = template['content']
    return [] if !first_content.is_a?(Array)

    first_content.flat_map { |content| content['content'] if content.is_a?(Hash) }.compact
  end
end
