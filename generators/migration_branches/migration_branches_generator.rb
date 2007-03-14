class MigrationBranchesGenerator < Rails::Generator::NamedBase

  def manifest
    record do | manifest_object |
      all_migrations = [ "#{file_name}:#{actions[0]}" ]
      actions.shift
      all_migrations << actions
      all_migrations.flatten!

      all_migrations.each do | migration_details |
        migration_name, branch_name = migration_details.split( ':' )
        branch_name = nil if branch_name == "default"
        class_name = migration_name.camelize
        file_name = migration_name.underscore

        # Create the migration file.
        manifest_object.migration_template( "migration.rb", 
        "db/migrate#{'/' + branch_name if branch_name}", 
        :assigns => { :migration_name => "#{class_name.pluralize.gsub( /::/, '' )}" }, 
        :migration_file_name => "create_#{file_name.gsub( /\//, '_' ).pluralize}"
        )
      end
    end
  end

  protected

  def banner
    "\nUsage:\n\t#{$0} generate migration_branches migration_name branch_name [migration_name[:branch_name] [...]]"
  end

  def add_options!( option )
    option.separator ''
    option.separator "Options:"
  end

end
