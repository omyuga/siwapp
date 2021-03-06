class Payment < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :invoice, touch: true  # "touch" changes invoice's updated_at on save
  validates :invoice_id, presence: true, numericality: {only_integer: true}
end
