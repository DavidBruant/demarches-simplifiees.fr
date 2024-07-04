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
      expect(export_template.content).to eq({
        "export_pdf" => export_conf(text: "export-", enabled: true),
        "dossier_folder" => export_conf(text: "dossier-", enabled: true),
        "pjs" => [pj_export_conf(stable_id: 3, text: "justificatif-de-domicile-", enabled: false)]
      })
    end
  end

  describe '#pj' do
    subject { export_template.pj(3) }

    it { is_expected.to eq(pj_export_conf(stable_id: 3, text: "justificatif-de-domicile-", enabled: false)) }
  end

  describe '#attachment_path' do
    context 'for export pdf' do
      let(:export_template) do
        create(:export_template, groupe_instructeur:).tap do
          _1.dossier_folder = export_conf(text: "DOSSIER_", enabled: true)
          _1.export_pdf = export_conf(text: "mon_export_", enabled: true)
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
      let(:export_template) { create(:export_template, groupe_instructeur:).tap { _1.pjs = [pj_export_conf(stable_id: 3, text: "justif_", enabled: true)] } }

      let(:attachment) { ActiveStorage::Attachment.new(name: 'pj', record: champ_pj, blob: ActiveStorage::Blob.new(filename: "superpj.png")) }

      it 'returns pj and custom name for pj' do
        expect(export_template.attachment_path(dossier, attachment, champ: champ_pj)).to eq("dossier-#{dossier.id}/justif_#{dossier.id}-1.png")
      end
    end
  end

  describe '#tiptap_convert' do
    context 'for date' do
      let(:export_template) do
        create(:export_template, groupe_instructeur:).tap do
          _1.export_pdf["template"]["content"] = [{ "type" => "paragraph", "content" => [{ "type" => "mention", "attrs" => { "id" => "dossier_depose_at", "label" => "date de dépôt" } }] }]
        end
      end
      let(:dossier) { create(:dossier, :en_construction, procedure:, depose_at: Date.parse("2024/03/30")) }

      it 'convert date with dash' do
        expect(export_template.export_pdf_path(dossier)).to eq "2024-03-30.pdf"
      end
    end
  end

  describe '#valid?' do
    let(:subject) { build(:export_template, groupe_instructeur:, content:) }
    let(:ddd_text) { "DoSSIER" }
    let(:mention) { { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } } }
    let(:ddd_mention) { mention }
    let(:pdf_text) { "export" }
    let(:pdf_mention) { mention }
    let(:pj_text) { "_pj" }
    let(:pj_mention) { mention }
    let(:content) do
      {
        "export_pdf" =>  {
          "enabled" => true,
          "template" => {
            "type" => "doc",
            "content" => [
              { "type" => "paragraph", "content" => [{ "text" => pdf_text, "type" => "text" }, pdf_mention] }
            ]
          }
        },
        "dossier_folder" => {
          "enabled" => true,
          "template" => {
            "type" => "doc",
            "content" => [
              { "type" => "paragraph", "content" => [{ "text" => ddd_text, "type" => "text" }, ddd_mention] }
            ]
          }
        },
        "pjs" =>
        [
          {
            template: { "type" => "doc", "content" => [{ "type" => "paragraph", "content" => [pj_mention, { "text" => pj_text, "type" => "text" }] }] },
            enabled: true,
            stable_id: "3"
          }
        ]
      }
    end

    context 'with valid dossier folder' do
      it 'has no error for dossier_folder' do
        expect(subject.valid?).to be_truthy
      end
    end

    context 'with no ddd text' do
      let(:ddd_text) { " " }
      context 'with mention' do
        let(:ddd_mention) { { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } } }
        it 'has no error for dossier_folder' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'without numéro de dossier' do
        let(:ddd_mention) { { "type" => "mention", "attrs" => { "id" => 'dossier_service_name', "label" => "nom du service" } } }
        it "add error for dossier_folder" do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:dossier_folder]).to be_present
          expect(subject.errors.full_messages).to include "Le champ « Nom du répertoire » doit contenir le numéro du dossier"
        end
      end
    end

    context 'with valid pdf name' do
      it 'has no error for pdf name' do
        expect(subject.valid?).to be_truthy
        expect(subject.errors[:export_pdf]).not_to be_present
      end
    end

    context 'with pdf text and without mention' do
      let(:pdf_text) { "export" }
      let(:pdf_mention) { { "type" => "mention", "attrs" => {} } }

      it "add no error" do
        expect(subject.valid?).to be_truthy
      end
    end

    context 'with no pdf text' do
      let(:pdf_text) { " " }

      context 'with mention' do
        it 'has no error for dossier_folder' do
          expect(subject.valid?).to be_truthy
          expect(subject.errors[:export_pdf]).not_to be_present
        end
      end

      context 'without mention' do
        let(:pdf_mention) { { "type" => "mention", "attrs" => {} } }
        it "add error for pdf name" do
          expect(subject.valid?).to be_falsey
          expect(subject.errors.full_messages).to include "Le champ « Nom du dossier au format pdf » doit être rempli"
        end
      end
    end

    context 'with no pj text' do
      let(:pj_text) { " " }

      context 'with mention' do
        it 'has no error for pj' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'without mention' do
        let(:pj_mention) { { "type" => "mention", "attrs" => {} } }
        it "add error for pj" do
          expect(subject.valid?).to be_falsey
          expect(subject.errors.full_messages).to include "Le champ « Justificatif de domicile » doit être rempli"
        end
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

  def pj_export_conf(stable_id:, text:, enabled:)
    export_conf(text: text, enabled: enabled).merge("stable_id" => stable_id.to_s)
  end

  def export_conf(text:, enabled:)
    {
      "enabled" => enabled,
      "template" => {
        "type" => "doc",
        "content" => content_conf(text:)
      }
    }
  end

  def content_conf(text:)
    [
      {
        "type" => "paragraph",
        "content" => [
          { "text" => text, "type" => "text" },
          { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }
        ]
      }
    ]
  end
end
