describe Logic::InRegionOperator do
  include Logic

  let(:tdc_commune) { create(:type_de_champ_communes) }
  let(:champ_commune) do
    Champs::CommuneChamp.new(code_postal: '92500', external_id: '92063', stable_id: tdc_commune.stable_id, type_de_champ: tdc_commune)
      .tap { |c| c.send(:on_codes_change) } # private method called before save to fill value, which is required for compute
  end

  let(:tdc_epci) { create(:type_de_champ_epci) }
  let(:champ_epci) do
    Champs::EpciChamp.new(code_departement: '43', code_region: '32', external_id: '244301016', stable_id: tdc_epci.stable_id, type_de_champ: tdc_epci)
      .tap do |c|
        c.send(:on_epci_name_changes)
      end # private method called before save to fill value, which is required for compute
  end

  let(:tdc_departement) { create(:type_de_champ_departements) }
  let(:champ_departement) { Champs::DepartementChamp.new(value: '01', stable_id: tdc_departement.stable_id, type_de_champ: tdc_departement) }

  describe '#compute' do
    context 'commune' do
      it { expect(ds_in_region(champ_value(champ_commune.stable_id), constant('11')).compute([champ_commune])).to be(true) }
    end

    context 'epci' do
      it do
        expect(ds_in_region(champ_value(champ_epci.stable_id), constant('84')).compute([champ_epci])).to be(true)
      end
    end

    context 'departement' do
      it { expect(ds_in_region(champ_value(champ_departement.stable_id), constant('84')).compute([champ_departement])).to be(true) }
    end
  end
end
