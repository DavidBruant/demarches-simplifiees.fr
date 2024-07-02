describe Logic::NotInRegionOperator do
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

  # let(:champ_commune) { create(:champ_communes, code_postal: '92500', external_id: '92063') }
  # let(:champ_epci) { create(:champ_epci, code_departement: '02', code_region: "32") }
  # let(:champ_departement) { create(:champ_departements, value: '01', code_region: '84') }

  describe '#compute' do
    context 'commune' do
      it do
        expect(ds_not_in_region(champ_value(champ_commune.stable_id), constant('11')).compute([champ_commune])).to be(false)
        expect(ds_not_in_region(champ_value(champ_commune.stable_id), constant('32')).compute([champ_commune])).to be(true)
      end
    end

    context 'epci' do
      it do
        expect(ds_not_in_region(champ_value(champ_epci.stable_id), constant('84')).compute([champ_epci])).to be(false)
        expect(ds_not_in_region(champ_value(champ_epci.stable_id), constant('11')).compute([champ_epci])).to be(true)
      end
    end

    context 'departement' do
      it do
        expect(ds_not_in_region(champ_value(champ_departement.stable_id), constant('84')).compute([champ_departement])).to be(false)
        expect(ds_not_in_region(champ_value(champ_departement.stable_id), constant('32')).compute([champ_departement])).to be(true)
      end
    end
  end
end
