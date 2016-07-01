class GlobalSettingsForm < ActiveForm
	attr_accessor :company_name, :company_vat_id, :company_address, 
	:company_phone, :company_email, :company_website, :company_logo, :currency, :legal_terms, :days_to_due
	validates_presence_of :company_name, :company_email
end