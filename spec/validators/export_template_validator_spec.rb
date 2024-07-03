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
end
