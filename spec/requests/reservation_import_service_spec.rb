require 'rails_helper'

RSpec.describe ReservationImportService, type: :service do
  let(:user) { create(:user) }
  let(:unit) { create(:unit) }
  let(:term) { create(:term) }
  let(:program) { create(:program, unit: unit, term: term) }
  let(:site) { create(:site, unit: unit) }
  let(:car) { create(:car, unit: unit) }
  let(:student) { create(:student, program: program) }
  let(:manager) { create(:manager) }
  
  # Create unit preferences for time validation
  let!(:time_begin_pref) { create(:unit_preference, name: "reservation_time_begin", unit: unit, value: "8:00 AM") }
  let!(:time_end_pref) { create(:unit_preference, name: "reservation_time_end", unit: unit, value: "5:00 PM") }

  describe '#call' do
    let(:csv_content) do
      <<~CSV
        TERM ID,TERM NAME,PROGRAM ID,PROGRAM TITLE,SITE ID,SITE TITLE,START DATE,START TIME,END DATE,END TIME,NUMBER OF PEOPLE ON TRIP,DRIVER,PASSENGERS,RECURRING DAYS,UNTIL DATE
        #{term.id},#{term.name},#{program.id},#{program.title},#{site.id},#{site.title},12/15/2025,10:00 AM,12/15/2025,2:00 PM,4,#{student.uniqname},#{manager.uniqname},"1,2,3",12/20/2025
      CSV
    end

    let(:csv_file) do
      file = Tempfile.new(['test', '.csv'])
      file.write(csv_content)
      file.rewind
      file
    end

    let(:uploaded_file) do
      ActionDispatch::Http::UploadedFile.new(
        tempfile: csv_file,
        filename: 'test_reservations.csv',
        type: 'text/csv'
      )
    end

    subject { described_class.new(uploaded_file, unit.id, user) }

    before do
      # Associate site with program
      program.sites << site
      # Make student a valid driver
      student.update(driver_training_completed: true)
      # Make manager part of the program
      program.managers << manager
    end

    after do
      csv_file.close
      csv_file.unlink
    end

    context 'with valid CSV data' do
      it 'successfully imports reservations' do
        expect { subject.call }.to change(Reservation, :count).by(1)
      end

      it 'returns success result' do
        result = subject.call
        
        expect(result[:errors]).to eq(0)
        expect(result[:note]).to include(/Reservations import completed/)
      end

      it 'creates reservation with correct attributes' do
        subject.call
        reservation = Reservation.last
        
        expect(reservation.program).to eq(program)
        expect(reservation.site).to eq(site)
        expect(reservation.number_of_people_on_trip).to eq(4)
        expect(reservation.reserved_by).to eq(user.id)
        expect(reservation.driver).to eq(student)
      end

      it 'assigns passengers correctly' do
        subject.call
        reservation = Reservation.last
        
        expect(reservation.passengers_managers).to include(manager)
      end
    end

    context 'with invalid term data' do
      let(:csv_content) do
        <<~CSV
          TERM ID,TERM NAME,PROGRAM ID,PROGRAM TITLE,SITE ID,SITE TITLE,START DATE,START TIME,END DATE,END TIME,NUMBER OF PEOPLE ON TRIP,DRIVER,PASSENGERS
          999,Invalid Term,#{program.id},#{program.title},#{site.id},#{site.title},12/15/2025,10:00 AM,12/15/2025,2:00 PM,4,#{student.uniqname},
        CSV
      end

      it 'returns error for invalid term' do
        result = subject.call
        
        expect(result[:errors]).to be > 0
        expect(result[:note].join).to include('Term Invalid Term or 999 not found')
      end

      it 'does not create reservation' do
        expect { subject.call }.not_to change(Reservation, :count)
      end
    end

    context 'with invalid program data' do
      let(:csv_content) do
        <<~CSV
          TERM ID,TERM NAME,PROGRAM ID,PROGRAM TITLE,SITE ID,SITE TITLE,START DATE,START TIME,END DATE,END TIME,NUMBER OF PEOPLE ON TRIP,DRIVER,PASSENGERS
          #{term.id},#{term.name},999,Invalid Program,#{site.id},#{site.title},12/15/2025,10:00 AM,12/15/2025,2:00 PM,4,#{student.uniqname},
        CSV
      end

      it 'returns error for invalid program' do
        result = subject.call
        
        expect(result[:errors]).to be > 0
        expect(result[:note].join).to include('Program #Invalid Program or #999 not found for unit')
      end
    end

    context 'with invalid site data' do
      let(:csv_content) do
        <<~CSV
          TERM ID,TERM NAME,PROGRAM ID,PROGRAM TITLE,SITE ID,SITE TITLE,START DATE,START TIME,END DATE,END TIME,NUMBER OF PEOPLE ON TRIP,DRIVER,PASSENGERS
          #{term.id},#{term.name},#{program.id},#{program.title},999,Invalid Site,12/15/2025,10:00 AM,12/15/2025,2:00 PM,4,#{student.uniqname},
        CSV
      end

      it 'returns error for invalid site' do
        result = subject.call
        
        expect(result[:errors]).to be > 0
        expect(result[:note].join).to include('Site #Invalid Site or #999 not found for unit')
      end
    end

    context 'with invalid time format' do
      let(:csv_content) do
        <<~CSV
          TERM ID,TERM NAME,PROGRAM ID,PROGRAM TITLE,SITE ID,SITE TITLE,START DATE,START TIME,END DATE,END TIME,NUMBER OF PEOPLE ON TRIP,DRIVER,PASSENGERS
          #{term.id},#{term.name},#{program.id},#{program.title},#{site.id},#{site.title},invalid-date,10:00 AM,12/15/2025,2:00 PM,4,#{student.uniqname},
        CSV
      end

      it 'returns error for invalid time format' do
        result = subject.call
        
        expect(result[:errors]).to be > 0
        expect(result[:note].join).to include('Invalid time format')
      end
    end

    context 'with time outside unit preferences' do
      let(:csv_content) do
        <<~CSV
          TERM ID,TERM NAME,PROGRAM ID,PROGRAM TITLE,SITE ID,SITE TITLE,START DATE,START TIME,END DATE,END TIME,NUMBER OF PEOPLE ON TRIP,DRIVER,PASSENGERS
          #{term.id},#{term.name},#{program.id},#{program.title},#{site.id},#{site.title},12/15/2025,6:00 AM,12/15/2025,7:00 AM,4,#{student.uniqname},
        CSV
      end

      it 'returns error for time outside unit preferences' do
        result = subject.call
        
        expect(result[:errors]).to be > 0
        expect(result[:note].join).to include('before allowed reservation time')
      end
    end

    context 'with invalid driver' do
      let(:csv_content) do
        <<~CSV
          TERM ID,TERM NAME,PROGRAM ID,PROGRAM TITLE,SITE ID,SITE TITLE,START DATE,START TIME,END DATE,END TIME,NUMBER OF PEOPLE ON TRIP,DRIVER,PASSENGERS
          #{term.id},#{term.name},#{program.id},#{program.title},#{site.id},#{site.title},12/15/2025,10:00 AM,12/15/2025,2:00 PM,4,invalid_driver,
        CSV
      end

      it 'returns error for invalid driver' do
        result = subject.call
        
        expect(result[:errors]).to be > 0
        expect(result[:note].join).to include("Student 'invalid_driver' is not enrolled in program")
      end
    end
  end

  describe 'private methods' do
    subject { described_class.new(uploaded_file, unit.id, user) }

    describe '#convert_date_format' do
      it 'converts date format correctly' do
        result = subject.send(:convert_date_format, "12/15/2025")
        expect(result).to eq("2025-12-15")
      end

      it 'handles invalid date format' do
        expect(subject.send(:convert_date_format, "invalid-date")).to be_nil
      end

      it 'handles blank input' do
        expect(subject.send(:convert_date_format, "")).to be_nil
        expect(subject.send(:convert_date_format, nil)).to be_nil
      end
    end

    describe '#convert_days_to_numbers' do
      it 'converts day names to numbers' do
        result = subject.send(:convert_days_to_numbers, "Monday, Tuesday, Wednesday")
        expect(result).to eq([1, 2, 3])
      end

      it 'handles mixed case' do
        result = subject.send(:convert_days_to_numbers, "SUNDAY, friday")
        expect(result).to eq([0, 5])
      end

      it 'handles blank input' do
        expect(subject.send(:convert_days_to_numbers, "")).to eq([])
        expect(subject.send(:convert_days_to_numbers, nil)).to eq([])
      end
    end

    describe '#string_to_number_array' do
      it 'converts comma-separated numbers' do
        result = subject.send(:string_to_number_array, "1,2,3,4,5")
        expect(result).to eq([1, 2, 3, 4, 5])
      end

      it 'handles spaces' do
        result = subject.send(:string_to_number_array, "1, 2, 3")
        expect(result).to eq([1, 2, 3])
      end

      it 'handles blank input' do
        expect(subject.send(:string_to_number_array, "")).to eq([])
        expect(subject.send(:string_to_number_array, nil)).to eq([])
      end
    end
  end
end