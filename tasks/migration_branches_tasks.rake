
module Rake
  module TaskManager
    def remove_task( task_name )
      @tasks.delete( task_name.to_s )
    end
  end
end

namespace :db do

  Rake::application.remove_task("db:migrate") # Remove the Rails migration task from Rake Tasks.

  desc "Migrate the database through scripts in db/migrate. \n\tTarget a specific version with VERSION=x from the command line."
  task :migrate => :environment do
    branches = ( ENV["branches"] || ENV["BRANCHES"] || ENV["Branches"] ).to_s.strip.gsub( /\s/, "_" ).split( ',' )
    if branches.include?( "all" )
      all_branches =  ( `cd #{Dir.pwd}/db/migrate;ls -d */` ).gsub( /\/$/, '' ).split( "\n" )
      branches = all_branches.insert( 0, nil )
    elsif ( branches.nil? || branches.empty? )
      branches = [nil]
    end
    
    # Check if the working direcory has 'db/' directory
    unless (`cd #{Dir.pwd}; ls -d */ | grep db`).strip == "db/"
      raise StandardError.new("\nrake db:migrate must be run from the RAILS_ROOT directory!")
    end

    # Specify the default branch if branches are empty
    unless branches.find{ | x | x.to_s.match( /default:.*/ ) }.nil?
      branches.delete( "default" ) and branches.insert( 0, nil ) 
    end

    branches.uniq! # This should be changed to delete duplicate branches or error out on duplicate
    # Example: branch_1:3,branch_1:4

    branches.each do | branch |
      branch_name, target_version = ( branch.nil? ? [ nil, nil ] : branch.to_s.split( ':' ) )
      branch_name = nil if branch_name == "default"
      puts "==============================================================================="
      puts "= Migrating db/migrate/#{branch_name}#{ " to version #{target_version}" unless target_version.nil?}"
      puts "===============================================================================\n"

      target_version = ENV["VERSION"] if ( branch_name.nil? && target_version.nil? && !ENV["VERSION"].nil? && ENV["VERSION"].to_i > 0 )

      ActiveRecord::Migrator.migrate( "db/migrate/", target_version ? target_version.to_i : nil, branch_name )

      puts ""
    end
    puts "** Finished migrating through branches:\n    #{branches.map{ | element | ( element || "default" ) }.join( ", " )}"
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  namespace :migrate do
  
    # rake db:migrate:list_branch
    desc "List all branches."
    task :list_branches => :environment do
      branches =  ( `cd #{Dir.pwd}/db/migrate; ls -d */` ).gsub( /\/$/, '' ).split( "\n" )
      puts "Branches:\n\tdefault"
      branches.each do | branch_name |
        puts "\t#{branch_name}"
      end
    end
  end
end
