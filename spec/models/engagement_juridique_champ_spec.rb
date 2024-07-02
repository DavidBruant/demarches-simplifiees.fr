describe Champs::EngagementJuridiqueChamp do
  describe 'validation' do
    let(:champ) do
      described_class
        .new(type_de_champ: build(:type_de_champ_engagement_juridique), dossier: build(:dossier))
        .tap { _1.value = value }
    end
    subject { champ.validate(:champs_public_value) }

    context 'with [A-Z]' do
      let(:value) { "ABC" }
      it { is_expected.to be_truthy }
    end

    context 'with [0-9]' do
      let(:value) { "ABC" }
      it { is_expected.to be_truthy }
    end

    context 'with -' do
      let(:value) { "-" }
      it { is_expected.to be_truthy }
    end

    context 'with _' do
      let(:value) { "_" }
      it { is_expected.to be_truthy }
    end

    context 'with +' do
      let(:value) { "+" }
      it { is_expected.to be_truthy }
    end

    context 'with /' do
      let(:value) { "/" }
      it { is_expected.to be_truthy }
    end

    context 'with *' do
      let(:value) { "*" }
      it { is_expected.to be_falsey }
    end
  end
end
