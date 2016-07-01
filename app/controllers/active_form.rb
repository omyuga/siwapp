require 'active_support/inflector'
require 'active_support/core_ext/hash/except'
require 'active_model'

class ActiveForm
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  def to_model; self; end
  def persisted?; false; end
  def to_key; nil; end
  def to_param; nil; end

  def initialize(attributes = nil)
    # Mass Assignment implementation
    if attributes
      attributes.each do |key, value|
        self[key] = value
      end
    end
    yield self if block_given?
  end
  
  def [](key)
    instance_variable_get("@#{key}")
  end
  
  def []=(key, value)
    instance_variable_set("@#{key}", value)
  end
  
  def method_missing(method_id, *params)
    # Implement _before_type_cast accessors
    if md = /_before_type_cast$/.match(method_id.to_s)
      attr_name = md.pre_match
      return self[attr_name] if self.respond_to?(attr_name)
    end
    super
  end

  def new_record?
    true
  end

  def id
    nil
  end

  def raise_not_implemented_error(*params)
    self.class.raise_not_implemented_error(params)
  end
  
  alias save raise_not_implemented_error
  alias save! raise_not_implemented_error
  alias update_attribute raise_not_implemented_error
  alias update_attributes raise_not_implemented_error
  alias save valid?
  alias save! raise_not_implemented_error
  alias update_attribute raise_not_implemented_error
  alias update_attributes raise_not_implemented_error
  
  class <<self
    def human_name(*args)
      name.to_s.humanize
    end

    def human_attribute_name(attribute_key_name, options={})
      attribute_key_name.to_s.humanize
    end

    def raise_not_implemented_error(*params)
      raise NotImplementedError
    end
    
    alias create raise_not_implemented_error
    alias create! raise_not_implemented_error
    alias validates_acceptance_of raise_not_implemented_error
    alias validates_uniqueness_of raise_not_implemented_error
    alias validates_associated raise_not_implemented_error
    alias validates_on_create raise_not_implemented_error
    alias validates_on_update raise_not_implemented_error
    alias save_with_validation raise_not_implemented_error
  end
end