require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.class_name = (options[:class_name] || name.to_s.classify)
    self.foreign_key = (options[:foreign_key] || (name.downcase.to_s + "_id").to_sym)
    self.primary_key = (options[:primary_key] || :id)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.class_name = (options[:class_name] || name.classify)
    self.foreign_key = (options[:foreign_key] || (self_class_name.downcase + "_id").to_sym)
    self.primary_key = (options[:primary_key] || :id)
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      target_id = self.send("#{options.foreign_key.to_sym}")
      options.model_class.where({id: target_id}).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, options)
    define_method(name) do
      self_id = self.send("#{options.foreign_key.to_sym}")
      options.model_class.where(options.foreign_key self_id)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
