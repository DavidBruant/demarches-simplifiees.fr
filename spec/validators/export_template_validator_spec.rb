describe ExportTemplateValidator do
  let(:validator) { ExportTemplateValidator.new }

  describe '.leaves' do
    subject { validator.send(:leaves, template) }

    context 'with a string' do
      let(:template) { 'invalid' }

      it { is_expected.to eq([]) }
    end

    context 'with a well formed tiptap content' do
      let(:template) do
        {
          "content" => [{ 'content' => [:leaf_1, :leaf_2] }, { 'content' => [:leaf_3] }]
        }
      end

      it { is_expected.to eq([:leaf_1, :leaf_2, :leaf_3]) }
    end
  end

  describe '.texts' do
    subject { validator.send(:texts, leaves) }

    context 'with some text' do
      let(:leaves) { [{ 'type' => 'text', 'text' => 'hello' }, { 'type' => 'mention' }] }

      it { is_expected.to eq(['hello']) }
    end

    context 'with a empty text' do
      let(:leaves) { [{ 'type' => 'text', 'text' => '' }] }

      it { is_expected.to eq([]) }
    end
  end

  describe 'validate' do
    let(:exportables_pieces_jointes) { [double('pj', stable_id: 3, libelle: 'libelle')] }
    let(:pj_libelle_by_stable_id) { exportables_pieces_jointes.map { |pj| [pj.stable_id.to_s, pj.libelle] }.to_h }
    let(:procedure) { double('procedure', exportables_pieces_jointes:) }
    let(:default_export_template) do
      ExportTemplate.new.tap do |export_template|
        allow(export_template).to receive(:procedure).and_return(procedure)
        allow(validator).to receive(:pj_libelle_by_stable_id).and_return(pj_libelle_by_stable_id)
        export_template.set_default_values
      end
    end

    def empty_template(enabled: true)
      { "template" => { "type" => "doc", "content" => [] }, "enabled" => enabled }
    end

    def errors(export_template) = export_template.errors.map { [_1.attribute, _1.message] }

    subject { validator.validate(export_template) }

    before { subject }

    context 'with a default export template' do
      let(:export_template) { default_export_template }

      it { expect(export_template.errors.count).to eq(0) }
    end

    context 'with a empty export_pdf' do
      let(:export_template) do
        default_export_template.tap { _1.export_pdf = empty_template }
      end

      it { expect(errors(export_template)).to eq([[:export_pdf, "doit être rempli"]]) }
    end

    context 'with a empth export_pdf disabled' do
      let(:export_template) do
        default_export_template.tap { _1.export_pdf = empty_template(enabled: false) }
      end

      it { expect(export_template.errors.count).to eq(0) }
    end

    context 'with a dossier_folder without dossier_number' do
      let(:export_template) do
        default_export_template.tap do |export_template|
          export_template.dossier_folder['template']['content'] = [{ 'content' => [{ 'type' => 'mention', 'attrs' => { 'id' => 'other' } }] }]
        end
      end

      it { expect(errors(export_template)).to eq([[:dossier_folder, "doit contenir le numéro du dossier"]]) }
    end

    context 'with a empty pj' do
      let(:export_template) { default_export_template.tap { _1.pjs.first.merge!(empty_template) } }

      it { expect(errors(export_template)).to eq([[:libelle, "doit être rempli"]]) }
    end

    context 'with a empty pj disabled' do
      let(:export_template) do
        default_export_template.tap { _1.pjs.first.merge!(empty_template(enabled: false)) }
      end

      it { expect(export_template.errors.count).to eq(0) }
    end
  end
end
