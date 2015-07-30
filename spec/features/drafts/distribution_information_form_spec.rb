# MMT-292

require 'rails_helper'

describe 'Distribution information form', js: true do
  before do
    login
    draft = create(:draft, user: User.where(urs_uid: 'testuser').first)
    visit draft_path(draft)
  end

  context 'when submitting the form' do
    before do
      click_on 'Distribution Information'

      # Complete RelatedUrl fields
      within '.multiple.related-url' do
        within '.multiple.related-url-url' do
          fill_in 'URL', with: 'http://example.com'
          click_on 'Add another'
          within all('.multiple-item').last do
            fill_in 'URL', with: 'http://another-example.com'
          end
        end
        fill_in 'Description', with: 'Example Description'
        select 'FTP', from: 'Protocol'
        fill_in 'Mime Type', with: 'text/html'
        fill_in 'Caption', with: 'Example Caption'
        fill_in 'Title', with: 'Example Title'
        fill_in 'File Size: Size', with: '42'
        fill_in 'File Size: Unit', with: 'MB'
        fill_in 'Content Type: Type', with: 'Text'
        fill_in 'Content Type: Subtype', with: 'Subtext'

        # Add another RelatedUrl
        within '.multiple-item-0 .accordion-header' do
          click_on 'Add another'
        end

        within '.multiple-item-1' do
          within '.multiple.related-url-url' do
            fill_in 'URL', with: 'http://example.com/1'
            click_on 'Add another'
            within all('.multiple-item').last do
              fill_in 'URL', with: 'http://another-example.com/1'
            end
          end
          fill_in 'Description', with: 'Example Description 1'
          select 'SSH', from: 'Protocol'
          fill_in 'Mime Type', with: 'text/json'
          fill_in 'Caption', with: 'Example Caption 1'
          fill_in 'Title', with: 'Example Title 1'
          fill_in 'File Size: Size', with: '4.2'
          fill_in 'File Size: Unit', with: 'GB'
          fill_in 'Content Type: Type', with: 'Text 1'
          fill_in 'Content Type: Subtype', with: 'Subtext 1'
        end
      end

      # Complete Distribution fields
      within '.multiple.distribution' do
        fill_in 'Distribution Media', with: 'Online Download'
        fill_in 'Distribution Size', with: '42 MB'
        fill_in 'Distribution Format', with: 'HDF'
        fill_in 'Fees', with: '0'

        # Add another Distribution
        within '.multiple-item-0 .accordion-header' do
          click_on 'Add another'
        end

        within '.multiple-item-1' do
          fill_in 'Distribution Media', with: 'Floppy disc'
          fill_in 'Distribution Size', with: '1.44 MB'
          fill_in 'Distribution Format', with: '.txt'
          fill_in 'Fees', with: '0'
        end
      end

      within '.nav-top' do
        click_on 'Save & Done'
      end
    end

    it 'shows the draft preview page' do
      expect(page).to have_content('Title Example DRAFT RECORD')
    end

    # TODO MMT-299
    it 'shows the values in the draft preview page'

    context 'when returning to the form' do
      before do
        click_on 'Distribution Information'

        # Expand first RelatedUrl item
        within '.multiple.related-url' do
          within '.multiple-item-0' do
            find('.accordion-header').click
          end
        end

        # Expand first Distribution item
        within '.multiple.distribution' do
          within '.multiple-item-0' do
            find('.accordion-header').click
          end
        end
      end

      it 'populates the form with the values' do
        within '.multiple.related-url' do
          within '.multiple-item-0' do
            expect(page).to have_field('URL', with: 'http://example.com')
            expect(page).to have_field('URL', with: 'http://another-example.com')
            expect(page).to have_field('Description', with: 'Example Description')
            expect(page).to have_field('Protocol', with: 'FTP')
            expect(page).to have_field('Mime Type', with: 'text/html')
            expect(page).to have_field('Caption', with: 'Example Caption')
            expect(page).to have_field('Title', with: 'Example Title')
            expect(page).to have_field('File Size: Size', with: '42')
            expect(page).to have_field('File Size: Unit', with: 'MB')
            expect(page).to have_field('Content Type: Type', with: 'Text')
            expect(page).to have_field('Content Type: Subtype', with: 'Subtext')
          end

          within '.multiple-item-1' do
            expect(page).to have_field('URL', with: 'http://example.com/1')
            expect(page).to have_field('URL', with: 'http://another-example.com/1')
            expect(page).to have_field('Description', with: 'Example Description 1')
            expect(page).to have_field('Protocol', with: 'SSH')
            expect(page).to have_field('Mime Type', with: 'text/json')
            expect(page).to have_field('Caption', with: 'Example Caption 1')
            expect(page).to have_field('Title', with: 'Example Title 1')
            expect(page).to have_field('File Size: Size', with: '4.2')
            expect(page).to have_field('File Size: Unit', with: 'GB')
            expect(page).to have_field('Content Type: Type', with: 'Text 1')
            expect(page).to have_field('Content Type: Subtype', with: 'Subtext 1')
          end
        end

        within '.multiple.distribution' do
          within '.multiple-item-0' do
            expect(page).to have_field('Distribution Media', with: 'Online Download')
            expect(page).to have_field('Distribution Size', with: '42 MB')
            expect(page).to have_field('Distribution Format', with: 'HDF')
            expect(page).to have_field('Fees', with: '0')
          end

          within '.multiple-item-1' do
            expect(page).to have_field('Distribution Media', with: 'Floppy disc')
            expect(page).to have_field('Distribution Size', with: '1.44 MB')
            expect(page).to have_field('Distribution Format', with: '.txt')
            expect(page).to have_field('Fees', with: '0')
          end
        end

      end

    end
  end
end
