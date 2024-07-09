class ExportTemplateValidator < ActiveModel::Validator
  def validate(export_template)
    validate_dossier_folder(export_template)
    validate_export_pdf(export_template)
    validate_pjs(export_template)
  end

  private

  def validate_dossier_folder(export_template)
    mentions = export_template.dossier_folder.mention_ids

    if !'dossier_number'.in?(mentions)
      export_template.errors.add(:dossier_folder, :dossier_number_mandatory)
    end
  end

  def validate_export_pdf(export_template)
    return if !export_template.export_pdf.enabled?

    export_pdf = export_template.export_pdf

    if export_pdf.texts.empty? && export_pdf.mention_ids.empty?
      export_template.errors.add(:export_pdf, :blank)
    end
  end

  def validate_pjs(export_template)
    libelle_by_stable_ids = pj_libelle_by_stable_id(export_template)

    export_template.pjs.each do |pj|
      next if !pj.enabled?

      if pj.texts.empty? && pj.mention_ids.empty?
        libelle = libelle_by_stable_ids[pj.stable_id]
        export_template.errors.add(libelle, I18n.t(:blank, scope: 'errors.messages'))
      end
    end
  end

  def pj_libelle_by_stable_id(export_template)
    pjs = export_template.groupe_instructeur.procedure.exportables_pieces_jointes
    pjs.pluck(:stable_id, :libelle).to_h { |sid, l| [sid.to_s, l] }
  end
end
