class ModelInBranchGenerator < Rails::Generator::NamedBase

  default_options :skip_migration => false

  def manifest
    record do | manifest_object |
      # Check for class naming collisions.
      manifest_object.class_collisions class_path, class_name, "#{class_name}Test"

      # Model, test, and fixture directories.
      manifest_object.directory File.join( "app/models", class_path )
      manifest_object.directory File.join( "test/unit", class_path )
      manifest_object.directory File.join( "test/fixtures", class_path )

      # Model class, unit test, and fixtures.
      manifest_object.template "model.rb",      File.join( "app/models", class_path, "#{file_name}.rb" )
      manifest_object.template "unit_test.rb",  File.join( "test/unit", class_path, "#{file_name}_test.rb" )
      manifest_object.template "fixtures.yml",  File.join( "test/fixtures", class_path, "#{table_name}.yml" )

      branch_name = ( actions[0] == "default" ) ? nil : actions[0] and actions.shift
      puts "Branch Name: #{branch_name}"
      puts "File Name: #{file_name}"

      unless options[:skip_migration]
        manifest_object.migration_template "migration.rb", "db/migrate#{'/' + branch_name if branch_name}", 
        :assigns => { :migration_name => "Create#{class_name.pluralize.gsub( /::/, '' )}",
        :attributes     => attributes }, 
        :migration_file_name => "create_#{file_path.gsub( /\//, '_' ).pluralize}"
      end
      
      unless options[:skip_data]
        # Create the default data yaml file
        manifest_object.directory File.join( "db/data#{'/' + branch_name if branch_name}" )

        manifest_object.template "branch_name.rb", 
         File.join( "db/data#{'/' + branch_name if branch_name}", "#{branch_name}.rb" ), 
         :assigns => { :branch_name => branch_name }

        manifest_object.template "model.yml", 
          File.join( "db/data", "#{'/' + branch_name if branch_name}/#{file_name.pluralize}.yml" ), 
         :assigns => { :model_name => file_name }
      end
      
    end
  end

  protected

  def banner
    "Usage: #{$0} generate ModelName [branch_name, field:type, [field:type, [...]]]"
  end

  def add_options!( option )
    option.separator ''
    option.separator 'Options:'

    option.on( "--skip-migration", "Don't generate a migration file for this model" ) do | value |
      options[:skip_migration] = v
    end

    option.on( "--skip-data", "Don't generate a default yaml file for this model" ) do | value |
      options[:skip_data] = true
    end
  end
end
