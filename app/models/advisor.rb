class Advisor < ApplicationRecord
  belongs_to :agency
  validates :name, presence: true
  validates :email, presence: true,
                    format: {      with: URI::MailTo::EMAIL_REGEXP }
  X="1"
end
