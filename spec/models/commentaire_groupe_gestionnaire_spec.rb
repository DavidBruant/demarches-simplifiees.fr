describe CommentaireGroupeGestionnaire, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:groupe_gestionnaire) }
    it { is_expected.to belong_to(:gestionnaire).optional }
    it { is_expected.to belong_to(:sender) }
  end

  describe "#soft_deletable?" do
    subject { commentaire_groupe_gestionnaire.soft_deletable?(user) }

    let(:commentaire_groupe_gestionnaire) { build :commentaire_groupe_gestionnaire, sender: sender, gestionnaire: gestionnaire }

    context 'with a commentaire_groupe_gestionnaire created by an administrateur deleted by administrateur' do
      let(:sender) { create(:administrateur) }
      let(:user) { sender }
      let(:gestionnaire) { nil }

      it { is_expected.to be_falsy }
    end

    context 'with a commentaire_groupe_gestionnaire created by an administrateur deleted by gestionnaire' do
      let(:sender) { create(:administrateur) }
      let(:user) { create(:gestionnaire) }
      let(:gestionnaire) { nil }

      it { is_expected.to be_falsy }
    end

    context 'with a commentaire_groupe_gestionnaire created by an gestionnaire deleted by gestionnaire' do
      let(:sender) { create(:gestionnaire) }
      let(:user) { sender }
      let(:gestionnaire) { sender }

      it { is_expected.to be_truthy }
    end

    context 'with a commentaire_groupe_gestionnaire created by an gestionnaire deleted by administrateur' do
      let(:sender) { create(:gestionnaire) }
      let(:user) { create(:administrateur) }
      let(:gestionnaire) { sender }

      it { is_expected.to be_falsy }
    end
  end

  describe "#sent_by?" do
    subject { commentaire_groupe_gestionnaire.sent_by?(user) }

    let(:commentaire_groupe_gestionnaire) { build :commentaire_groupe_gestionnaire, sender: sender }

    context 'with a commentaire_groupe_gestionnaire created by an administrateur so sent by administrateur' do
      let(:sender) { create(:administrateur) }
      let(:user) { sender }

      it { is_expected.to be_truthy }
    end

    context 'with a commentaire_groupe_gestionnaire created by an administrateur so not sent by gestionnaire' do
      let(:sender) { create(:administrateur) }
      let(:user) { create(:gestionnaire) }

      it { is_expected.to be_falsy }
    end

    context 'with a commentaire_groupe_gestionnaire created by an gestionnaire so sent by gestionnaire' do
      let(:sender) { create(:gestionnaire) }
      let(:user) { sender }

      it { is_expected.to be_truthy }
    end

    context 'with a commentaire_groupe_gestionnaire created by an gestionnaire so not sent by administrateur' do
      let(:sender) { create(:gestionnaire) }
      let(:user) { create(:administrateur) }

      it { is_expected.to be_falsy }
    end
  end
end
