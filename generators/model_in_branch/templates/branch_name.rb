class <%= branch_name.camelize %> < MigrationBranches::DataLoader
  def run()
    # Code goes here using models to 
  end
end

<%= branch_name.camelize %>.new.run
