class ExportTemplateValidator < ActiveModel::Validator
  def validate(export_template)
    validate_dossier_folder(export_template)
    validate_export_pdf(export_template)
    validate_pjs(export_template)
  end

  private

  def validate_dossier_folder(export_template)
    template = export_template.dossier_folder.template
    mentions = leaves(template).then { |leaves| mention_ids(leaves) }

    if !'dossier_number'.in?(mentions)
      export_template.errors.add(:dossier_folder, :dossier_number_mandatory)
    end
  end

  def validate_export_pdf(export_template)
    return if !export_template.export_pdf.enabled?

    template = export_template.export_pdf.template
    texts, mentions = leaves(template).then { |leaves| [texts(leaves), mention_ids(leaves)] }

    if texts.empty? && mentions.empty?
      export_template.errors.add(:export_pdf, :blank)
    end
  end

  def validate_pjs(export_template)
    libelle_by_stable_ids = pj_libelle_by_stable_id(export_template)

    export_template.pjs.each do |pj|
      next if !pj.enabled?

      texts, mentions = leaves(pj.template).then { |leaves| [texts(leaves), mention_ids(leaves)] }

      if texts.empty? && mentions.empty?
        libelle = libelle_by_stable_ids[pj.stable_id]
        export_template.errors.add(libelle, I18n.t(:blank, scope: 'errors.messages'))
      end
    end
  end

  def pj_libelle_by_stable_id(export_template)
    pjs = export_template.groupe_instructeur.procedure.exportables_pieces_jointes
    pjs.pluck(:stable_id, :libelle).to_h { |sid, l| [sid.to_s, l] }
  end

  def leaves(template)
    return [] if !template.is_a?(Hash)

    first_content = template['content']
    return [] if !first_content.is_a?(Array)

    first_content.flat_map { |content| content['content'] if content.is_a?(Hash) }.compact
  end

  def mention_ids(leaves)
    leaves
      .filter { |leaf| leaf['type'] == 'mention' }
      .map { |mention| mention['attrs']['id'] }
      .filter(&:present?)
  end

  def texts(leaves)
    leaves
      .filter { |leaf| leaf['type'] == 'text' }
      .map { |text| text['text'] }
      .filter(&:present?)
  end
end
