# Start to finish test of the approver workflow without mocking the inter-MMT
# communications.
describe 'When going through the whole collection proposal approver workflow', js: true do
  before do
    login(real_login: true)
    allow_any_instance_of(PermissionChecking).to receive(:is_non_nasa_draft_approver?).and_return(true)
    # FactoryGirl respects validations; need to be in proposal mode to create
    set_as_proposal_mode_mmt(with_draft_approver_acl: true)
  end

  context 'when loading the manage proposals page' do
    context 'when publishing a create metadata proposal' do
      before do
        @native_id = 'dmmt_collection_1'
        @proposal = create(:full_collection_draft_proposal, proposal_short_name: 'Full Workflow Create Test Proposal', proposal_entry_title: 'Test Entry Title', proposal_request_type: 'create', proposal_native_id: @native_id)
        mock_approve(@proposal)
        # Workflow is in mmt proper, so switch back
        set_as_mmt_proper
        # Mock URS communication because it has no concept of our test users
        mock_valid_token_validation
        visit manage_proposals_path

        # Mock URS call to get information to update status history
        mock_urs_get_users
        within '.open-draft-proposals tbody tr:nth-child(1)' do
          click_on 'Publish'
        end
        select 'MMT_2', from: 'provider-publish-target'
        within '#approver-proposal-modal' do
          click_on 'Publish'
        end
      end

      after do
        cmr_client.delete_collection('MMT_2', @native_id, 'ABC-2')
      end

      it 'displays expected success messages' do
        expect(page).to have_content('Collection Metadata Successfully Published!')
      end

      it 'updated proposal status in dMMT' do
        proposal = CollectionDraftProposal.find(@proposal.id)

        expect(proposal.proposal_status).to eq('done')
        expect(proposal.status_history['done']['username']).to eq('Test User')
        expect(Time.parse(proposal.status_history['done']['action_date']).utc).to be_within(1.second).of Time.now
      end

      context 'when searching for the new collection' do
        before do
          # Wait added to improve test consistency; appeared to be searching too
          # fast to find the added record
          wait_for_cmr
          fill_in 'keyword', with: 'MMT_2'
          click_on 'Search Collections'
        end

        it 'can find the record in CMR' do
          expect(page).to have_content('Full Workflow Create Test Proposal')
          expect(page).to have_content('Test Entry Title')
        end
      end
    end

    context 'when publishing an update metadata proposal' do
      before do
        @update_native_id = "dmmt_collection_#{Faker::Number.number(15)}"
        @proposal = create(:full_collection_draft_proposal, proposal_short_name: "Full Workflow Update Test Proposal_#{Faker::Number.number(15)}", proposal_entry_title: "Full Workflow Update Test Proposal_#{Faker::Number.number(15)}", proposal_request_type: 'update', proposal_native_id: @update_native_id)
        mock_approve(@proposal)
        # Workflow is in mmt proper, so switch back
        set_as_mmt_proper
        @ingest_response, _concept_response = publish_collection_draft(native_id: @update_native_id)

        # Mock URS communication because it has no concept of our test users
        mock_valid_token_validation
        visit manage_proposals_path

        # Mock URS call to get information to update status history
        mock_urs_get_users
        within '.open-draft-proposals tbody tr:nth-child(1)' do
          click_on 'Publish'
        end
        within '#approver-proposal-modal' do
          click_on 'Yes'
        end
      end

      after do
        cmr_client.delete_collection('MMT_2', @update_native_id, 'ABC-2')
      end

      it 'displays expected success messages' do
        expect(page).to have_content('Collection Metadata Successfully Published!')
      end

      it 'updated proposal status in dMMT' do
        proposal = CollectionDraftProposal.find(@proposal.id)

        expect(proposal.proposal_status).to eq('done')
        expect(proposal.status_history['done']['username']).to eq('Test User')
        expect(Time.parse(proposal.status_history['done']['action_date']).utc).to be_within(1.second).of Time.now
      end

      context 'when visiting the updated collection' do
        before do
          visit collection_path(@ingest_response['concept-id'])
        end

        it 'can find the record in CMR' do
          expect(page).to have_content('Full Workflow Update Test Proposal')
        end
      end
    end

    context 'when publishing a delete metadata proposal' do
      before do
        native_id = "dmmt_collection_#{Faker::Number.number(15)}"
        @proposal = create(:full_collection_draft_proposal, proposal_short_name: 'Full Workflow Delete Test Proposal', proposal_entry_title: 'Full Workflow Create Test Proposal', proposal_request_type: 'delete', proposal_native_id: native_id)
        mock_approve(@proposal)
        # Workflow is in mmt proper, so switch back
        set_as_mmt_proper
        @ingest_response, _concept_response = publish_collection_draft(native_id: native_id)
        # Mock URS communication because it has no concept of our test users
        mock_valid_token_validation
        visit manage_proposals_path

        # Mock URS call to get information to update status history
        mock_urs_get_users
        within '.open-draft-proposals tbody tr:nth-child(1)' do
          click_on 'Delete'
        end

        within '#approver-proposal-modal' do
          click_on 'Yes'
        end
      end

      it 'displays expected success messages' do
        expect(page).to have_content('Collection Metadata Deleted Successfully!')
      end

      it 'updated proposal status in dMMT' do
        proposal = CollectionDraftProposal.find(@proposal.id)

        expect(proposal.proposal_status).to eq('done')
        expect(proposal.status_history['done']['username']).to eq('Test User')
        expect(Time.parse(proposal.status_history['done']['action_date']).utc).to be_within(1.second).of Time.now
      end

      context 'when visiting the deleted collection' do
        before do
          visit collection_path(@ingest_response['concept-id'])
        end

        it 'cannot find the record in CMR' do
          expect(page).to have_content('This collection is not available. It is either being published right now, does not exist, or you have insufficient permissions to view this collection.')
        end
      end
    end
  end
end
