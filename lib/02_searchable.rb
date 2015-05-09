require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_conditions = []
    params.each {|k, v| where_conditions <<  "#{k} = '#{v}'"}
    where_line = where_conditions.join(' AND ')

    row = DBConnection::execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}
    SQL

    self.parse_all(row)
  end
end

class SQLObject
  extend Searchable
end
