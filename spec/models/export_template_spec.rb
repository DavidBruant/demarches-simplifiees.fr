describe ExportTemplate do
  let(:groupe_instructeur) { create(:groupe_instructeur, procedure:) }
  let(:export_template) { create(:export_template, groupe_instructeur:) }
  let(:procedure) { create(:procedure_with_dossiers, types_de_champ_public:, for_individual:) }
  let(:dossier) { procedure.dossiers.first }
  let(:for_individual) { false }
  let(:types_de_champ_public) do
    [
      { type: :piece_justificative, libelle: "Justificatif de domicile", mandatory: true, stable_id: 3 },
      { type: :titre_identite, libelle: "CNI", mandatory: true, stable_id: 5 }
    ]
  end

  describe 'set_default_values' do
    it 'set default values' do
      expect(export_template.export_pdf).to eq(export_item(text: "export-", enabled: true))
      expect(export_template.dossier_folder).to eq(export_item(text: "dossier-", enabled: true))
      expect(export_template.pjs).to eq([pj_export_item(stable_id: 3, text: "justificatif-de-domicile-", enabled: false)])
    end
  end

  describe '#pj' do
    subject { export_template.pj(3) }

    it { is_expected.to eq(pj_export_item(stable_id: 3, text: "justificatif-de-domicile-", enabled: false)) }
  end

  describe '#attachment_path' do
    context 'for export pdf' do
      let(:export_template) do
        create(:export_template, groupe_instructeur:).tap do
          _1.dossier_folder = export_item(text: "DOSSIER_", enabled: true)
          _1.export_pdf = export_item(text: "mon_export_", enabled: true)
        end
      end

      let(:attachment) { double("attachment") }

      it 'gives absolute filename for export of specific dossier' do
        allow(attachment).to receive(:name).and_return('pdf_export_for_instructeur')
        expect(export_template.attachment_path(dossier, attachment)).to eq("DOSSIER_#{dossier.id}/mon_export_#{dossier.id}.pdf")
      end
    end

    context 'for pj' do
      let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }
      let(:champ_pj) { dossier.champs_public.first }
      let(:export_template) { create(:export_template, groupe_instructeur:).tap { _1.pjs = [pj_export_item(stable_id: 3, text: "justif_", enabled: true)] } }

      let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

      it 'returns pj and custom name for pj' do
        expect(export_template.attachment_path(dossier, attachment, champ: champ_pj)).to eq("dossier-#{dossier.id}/justif_#{dossier.id}-1.png")
      end
    end
  end

  context 'for entreprise procedure' do
    let(:for_individual) { false }

    describe 'tags' do
      it do
        tags = export_template.tags
        expect(tags.map { _1[:id] }).to eq ["entreprise_siren", "entreprise_numero_tva_intracommunautaire", "entreprise_siret_siege_social", "entreprise_raison_sociale", "entreprise_adresse", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur"]
      end
    end

    describe 'pj_tags' do
      it do
        tags = export_template.pj_tags
        expect(tags.map { _1[:id] }).to eq ["entreprise_siren", "entreprise_numero_tva_intracommunautaire", "entreprise_siret_siege_social", "entreprise_raison_sociale", "entreprise_adresse", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur", "original-filename"]
      end
    end
  end

  context 'for individual procedure' do
    let(:for_individual) { true }

    describe 'tags' do
      it do
        tags = export_template.tags
        expect(tags.map { _1[:id] }).to eq ["individual_gender", "individual_last_name", "individual_first_name", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur"]
      end
    end

    describe 'pj_tags' do
      it do
        tags = export_template.pj_tags
        expect(tags.map { _1[:id] }).to eq ["individual_gender", "individual_last_name", "individual_first_name", "dossier_depose_at", "dossier_procedure_libelle", "dossier_service_name", "dossier_number", "dossier_groupe_instructeur", "original-filename"]
      end
    end
  end

  def pj_export_item(stable_id:, text:, enabled:)
    ExportItem.new('template' => template(text: text), 'enabled' => enabled, 'stable_id' => stable_id.to_s)
  end

  def export_item(text:, enabled:)
    ExportItem.new('template' => template(text: text), 'enabled' => enabled)
  end

  def template(text:)
    {
      "type" => "doc",
      "content" => [
        {
          "type" => "paragraph",
          "content" => [
            { "text" => text, "type" => "text" },
            { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }
          ]
        }
      ]
    }
  end
end
