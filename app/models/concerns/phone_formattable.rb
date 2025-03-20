module PhoneFormattable
  extend ActiveSupport::Concern

  def formatted_phone_number
    return nil if phone_number.blank?

    # Handle US format (most common case)
    if phone_number.length == 10
      "(#{phone_number[0..2]}) #{phone_number[3..5]}-#{phone_number[6..9]}"
    elsif phone_number.length == 11 && phone_number[0] == "1"
      "+1 (#{phone_number[1..3]}) #{phone_number[4..6]}-#{phone_number[7..10]}"
    else
      # For other formats, insert dashes for readability
      phone_number.gsub(/(\d{3})(\d{3})(\d{4})$/, '\\1-\\2-\\3')
    end
  end
end
