require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    columns = DBConnection::execute2(<<-SQL)
    SELECT
      *
    FROM
      '#{table_name}'
    LIMIT
      1
    SQL
    columns.first.map {|col| col.to_sym }
  end

  def self.columns_no_id
    self.columns.reject {|col| col == :id }
  end

  def self.finalize!
    self.columns.each do |col_name|
      define_method(col_name) do
        attributes[col_name]
      end
      define_method("#{col_name}=") do |value|
        attributes[col_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= "#{self}".downcase.pluralize
  end

  def self.all
    results = (DBConnection::execute(<<-SQL) )
    SELECT
      *
    FROM
      #{table_name}
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map { |row| self.new(row) }
  end

  def self.find(id)
    self.all.select { |obj| obj.id == id }.first
  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k.to_sym)
      self.send("#{k.to_sym}=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    col_names = self.class.columns.reject {|col| col == :id }.join(', ')
    values = self.attribute_values
    question_marks = ['?'] * values.length
    question_marks = '(' + question_marks.join(', ') + ')'
    DBConnection::execute(<<-SQL, values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      #{question_marks}
    SQL
    self.id = DBConnection::last_insert_row_id
  end

  def update
    set_line = self.class.columns_no_id.map {|col| "#{col} = ?"}.join(', ')
    values = self.attribute_values.drop(1)
    DBConnection::execute(<<-SQL, values)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = #{id}
    SQL
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end
end
