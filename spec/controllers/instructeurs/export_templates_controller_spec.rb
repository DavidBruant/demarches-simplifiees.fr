describe Instructeurs::ExportTemplatesController, type: :controller do
  before { sign_in(instructeur.user) }

  def pj_export_conf(stable_id:, text:, enabled:)
    export_conf(text: text, enabled: enabled).merge("stable_id" => stable_id.to_s)
  end

  def export_conf(text:, enabled:)
    {
      "enabled" => enabled,
      "template" => {
        "type" => "doc",
        "content" => content(text:)
      }.to_json
    }
  end

  def content(text:)
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

  let(:default_export_pdf) { export_conf(text: "mon_export_", enabled: true) }
  let(:export_pdf) { default_export_pdf }

  let(:export_template_params) do
    {
      name: "coucou",
      kind: "zip",
      groupe_instructeur_id: groupe_instructeur.id,
      export_pdf:,
      dossier_folder: export_conf(text: "DOSSIER_", enabled: true),
      pjs: [
        pj_export_conf(stable_id: 3, text: "avis-commission-", enabled: true),
        pj_export_conf(stable_id: 5, text: "avis-commission-", enabled: true),
        pj_export_conf(stable_id: 10, text: "avis-commission-", enabled: true)
      ]
    }
  end

  let(:instructeur) { create(:instructeur) }
  let(:procedure) do
    create(
      :procedure, instructeurs: [instructeur],
      types_de_champ_public: [
        { type: :piece_justificative, libelle: "pj1", stable_id: 3 },
        { type: :piece_justificative, libelle: "pj2", stable_id: 5 },
        { type: :piece_justificative, libelle: "pj3", stable_id: 10 }
      ]
    )
  end
  let(:groupe_instructeur) { procedure.defaut_groupe_instructeur }

  describe '#new' do
    subject { get :new, params: { procedure_id: procedure.id } }

    it do
      subject
      expect(assigns(:export_template)).to be_present
    end
  end

  describe '#create' do
    subject { post :create, params: { procedure_id: procedure.id, export_template: export_template_params } }

    context 'with valid params' do
      it 'redirect to some page' do
        subject
        expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
        expect(flash.notice).to eq "Le modèle d'export coucou a bien été créé"
      end
    end

    context 'with invalid params' do
      let(:export_pdf) do
        default_export_pdf.merge("template" => { "content" => [{ "content" => "invalid" }] }.to_json)
      end

      it 'display error notification' do
        subject
        expect(flash.alert).to be_present
      end
    end

    context 'with procedure not accessible by current instructeur' do
      let(:another_procedure) { create(:procedure) }
      subject { post :create, params: { procedure_id: another_procedure.id, export_template: export_template_params } }

      it 'raise exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#edit' do
    let(:export_template) { create(:export_template, groupe_instructeur:) }
    subject { get :edit, params: { procedure_id: procedure.id, id: export_template.id } }

    it 'render edit' do
      subject
      expect(response).to render_template(:edit)
    end

    context "with export_template not accessible by current instructeur" do
      let(:another_groupe_instructeur) { create(:groupe_instructeur) }
      let(:export_template) { create(:export_template, groupe_instructeur: another_groupe_instructeur) }

      it 'raise exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#update' do
    let(:export_template) { create(:export_template, groupe_instructeur:) }
    let(:export_pdf) do
      h = default_export_pdf.clone

      h["template"] = {
        "type" => "doc",
        "content" => [
          { "type" => "paragraph", "content" => [{ "text" => "exPort_", "type" => "text" }, { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } }] }
        ]
      }.to_json

      h
    end

    subject { put :update, params: { procedure_id: procedure.id, id: export_template.id, export_template: export_template_params } }

    context 'with valid params' do
      it 'redirect to some page' do
        subject
        expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
        expect(flash.notice).to eq "Le modèle d'export coucou a bien été modifié"
      end
    end

    context 'with invalid params' do
      let(:export_pdf) do
        default_export_pdf.merge("template" => { "content" => [{ "content" => "invalid" }] }.to_json)
      end

      it 'display error notification' do
        subject
        expect(flash.alert).to be_present
      end
    end
  end

  describe '#destroy' do
    let(:export_template) { create(:export_template, groupe_instructeur:) }
    subject { delete :destroy, params: { procedure_id: procedure.id, id: export_template.id } }

    context 'with valid params' do
      it 'redirect to some page' do
        subject
        expect(response).to redirect_to(exports_instructeur_procedure_path(procedure:))
        expect(flash.notice).to eq "Le modèle d'export Mon export a bien été supprimé"
      end
    end
  end

  describe '#preview' do
    render_views

    let(:export_template) { create(:export_template, groupe_instructeur:) }

    subject { get :preview, params: { procedure_id: procedure.id, id: export_template.id, export_template: export_template_params }, format: :turbo_stream }

    it '' do
      dossier = create(:dossier, procedure: procedure, for_procedure_preview: true)
      subject
      expect(response.body).to include "DOSSIER_#{dossier.id}"
      expect(response.body).to include "mon_export_#{dossier.id}.pdf"
    end
  end
end
