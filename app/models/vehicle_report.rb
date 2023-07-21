# == Schema Information
#
# Table name: vehicle_reports
#
#  id                   :bigint           not null, primary key
#  reservation_id       :bigint           not null
#  mileage_start        :float
#  mileage_end          :float
#  gas_start            :int
#  gas_end              :int
#  parking_spot         :string
#  created_by           :integer
#  updated_by           :integer
#  status               :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  student_status       :boolean          default false
#  approved             :boolean          default false
#  parking_spot_return  :string
#
class VehicleReport < ApplicationRecord
  belongs_to :reservation

  has_one_attached :image_front_start do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_one_attached :image_driver_start do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_one_attached :image_passenger_start do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_one_attached :image_back_start do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_one_attached :image_front_end do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_one_attached :image_driver_end do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_one_attached :image_passenger_end do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_one_attached :image_back_end do |attachable|
    attachable.variant :thumb, resize_to_limit: [150, 150]
   end
  has_many_attached :image_damages do |attachable|
   attachable.variant :thumb, resize_to_limit: [150, 150]
  end

  has_rich_text :comment
  has_rich_text :admin_comment
  has_many :notes, as: :noteable
  before_save :set_student_status
  before_save :set_admin_status

  def image_damages=(attachables)
    attachables = Array(attachables).compact_blank
    if attachables.any?
      attachment_changes["image_damages"] =
        ActiveStorage::Attached::Changes::CreateMany.new("image_damages", self, image_damages.blobs + attachables)
    end
  end

  validates_presence_of :reservation_id, :mileage_start, :gas_start
  validate :acceptable_documents
  validate :check_mileage_end
  validate :check_mileage_start
  validates :reservation_id, uniqueness: true

  scope :data, ->(reports_ids) { reports_ids.present? ? where(id: reports_ids.split(",").map(&:to_i)) : all }
  
  def car
    self.reservation.car
  end

  def program
    self.reservation.program
  end

  def site
    self.reservation.site
  end

  def driver
    self.reservation.driver
  end

  def acceptable_documents
    acceptable_types = [
      "application/pdf", "text/plain", "image/jpg", 
      "image/jpeg", "image/png", 
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    ]
    image_front_start do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_front_start.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
    image_passenger_start do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_passenger_start.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
    image_back_start do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_back_start.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
    image_back_start do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_back_start.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
    image_front_end do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_front_end.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
    image_driver_end do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_driver_end.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
    image_passenger_end do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_passenger_end.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
    image_back_end do
      unless doc.byte_size <= 20.megabyte
        errors.add(:documents, "is too big")
      end
      unless acceptable_types.include?(image_back_end.content_type)
        errors.add(:documents, "must be an acceptable file type (pdf,txt,jpg,png,doc)")
      end
    end
  end

  def check_mileage_end
    if self.mileage_end.present? && self.mileage_end < self.mileage_start
       errors.add("Mileage end must be bigger than mileage start - current value: ", mileage_end.to_s)
    end
  end

  def check_mileage_start
    if self.mileage_start.present? && self.mileage_start < 0
       errors.add("Mileage start must be a valid value - current value: ", mileage_start.to_s)
    end
  end

  def set_student_status
    if self.all_fields? && self.all_images?
      self.student_status = true
    else
      self.student_status = false
    end
  end

  def all_fields?
    self.attributes.except("id", "created_at", "updated_at", "updated_by", "created_by", "status", "note", "student_status", "approved", "parking_spot").all? {|k, v| v.present?} ? true : false
  end

  def set_admin_status
    if self.approved
      self.status = "Approved"
    else
      self.status = "Pending"
    end
  end

  def all_images?
    images_validated_start = false
    images_validated_end = false
    unless self.reservation.program.pictures_required_start
      images_validated_start = true
    end
    unless self.reservation.program.pictures_required_end
      images_validated_end = true
    end
    if images_validated_start && images_validated_end
      return true
    end
    if self.reservation.program.pictures_required_start
      if check_all_start_images?
        images_validated_start = true
      end
    else
      images_validated_start = true #set to true because validation not required
    end
    if self.reservation.program.pictures_required_end
      if check_all_end_images?
        images_validated_end = true
      end
    else
      images_validated_end = true #set to true because validation not required
    end
    return images_validated_start && images_validated_end
  end

  def check_all_start_images?
    self.image_front_start.attached? && self.image_driver_start.attached? && self.image_passenger_start.attached? && self.image_back_start.attached?
  end

  def check_all_end_images?
    self.image_front_end.attached? && self.image_driver_end.attached? && self.image_passenger_end.attached? && self.image_back_end.attached?
  end

end
