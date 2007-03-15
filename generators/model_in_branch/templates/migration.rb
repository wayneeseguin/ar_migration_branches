class <%= migration_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %>, :options => "CHARSET=utf8 COLLATION utf8_general_ci" do | table |
<% for attribute in attributes -%>
      table.column :<%= attribute.name %>, :<%= attribute.type %>
<% end -%>
    end
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
