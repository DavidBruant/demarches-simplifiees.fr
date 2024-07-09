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
    template['content'][0]['content'].map do
      if _1['type'] == 'text'
        tag.span(_1['text'])
      else
        tag.span(_1['attrs']['label'], class: 'fr-tag fr-tag--sm')
      end
    end.join.then { sanitize(_1) }
  end
end
