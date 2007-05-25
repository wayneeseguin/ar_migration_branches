# Copyright (c) 2006 Wayne E. Seguin
# 
# THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# MigrationBranches Ruby on Rails Plugin

module MigrationBranches
  class DataLoader

    attr_accessor :branch

    def initialize( branch = nil )
      # Load the Rails environment
      @@branch = branch
    end

    def yaml_path
      # #{RAILS_ROOT}/db/data/#{@@branch}/#{@@branch}.rb
    end

    def yaml_path
      # #{RAILS_ROOT}/db/data/#{@@branch}/#{@@branch}.rb
    end

    # Create records in join table given human readable field mapping and
    # both sides of join.
    # EXAMPLE:
    # branch_name: "assessment_question"
    # parent_class: Assessment
    # child_class: Question
    # join_class: AssessmentQuestion
    # map_field: "Question"
    # child_attribute: "code_name"
    #
    # load_join_table_data( 
    #   :file_name => "db/data/", 
    #   :parent => "Assessment", 
    #   :child => "Question", 
    #   :map_field => "Question", 
    #   :child_attribute => )

    def load_join_table_data_from_file( join_file_name )
      join_file_name.match
      parent = $1
      child = $2
      # parse file name to get parent and child class names
      # load file and get map_field, child_attribute
      self.load_join_table_data( options )
    end

    def load_join_table_data( options = { } )
      parent_class.find( :all ).each do | parent |
        begin
          # clear out the old mappings
          parent.send( join_class.name.underscore.pluralize ).destroy_all unless parent.send( join_class.class.name.underscore).empty?

          # load this parent's children from the yml file
          unless File.zero?( self.yaml_path )
            yaml = YAML.load( File.read( self.yaml_path ) ).each do | data |
              # create a new join record
              child_record = child_class.send( "find_by_#{child_attribute}( data['#{map_field}'] )" )
              new_join_record = parent.send( join_class.class.name.underscore ).new( data )
              new_join_record.send( child_class.class.name.underscore )# = child_record # What was the intent here?
              new_join_record.save
            end
          else
            # no join file, which should be impossible
          end
        rescue
          puts("Problem loading join data from #{self.yaml_path}: #{$!}")
        end
      end    
    end
  end
end

module ActiveRecord

  class Migrator#:nodoc:
    class << self
      alias_method_chain :migrate, :branches
      def migrate_with_branches( migrations_path, target_version = nil, branch = nil )
        @@branch = branch
        unless @@branch.blank?
          begin
            version_field = @@branch.nil? ? "version" : "version_#{@@branch}"
            Base.connection.execute( "ALTER TABLE #{ActiveRecord::Migrator.schema_info_table_name} ADD #{version_field} int(11) UNSIGNED DEFAULT 0;" )
          rescue ActiveRecord::StatementInvalid
            # Schema for branch has already been intialized
          end
        end
        
        migrate_without_branches
      end
      #def migrate( migrations_path, target_version = nil, branch = nil )
      #
      #  Base.connection.initialize_schema_information
      #
      #  unless @@branch.blank?
      #    begin
      #      version_field = @@branch.nil? ? "version" : "version_#{@@branch}"
      #      Base.connection.execute( "ALTER TABLE #{ActiveRecord::Migrator.schema_info_table_name} ADD #{version_field} int(11) UNSIGNED DEFAULT 0;" )
      #      #Base.connection.execute( "INSERT INTO #{ActiveRecord::Migrator.schema_info_table_name} ( #{version_field} ) VALUES(0)" )
      #    rescue ActiveRecord::StatementInvalid
      #      # Schema for branch has already been intialized
      #    end
      #  end
      #
      #  case
      #  when target_version.nil?, current_version < target_version
      #    up( migrations_path, target_version )
      #  when current_version > target_version
      #    down( migrations_path, target_version )
      #  when current_version == target_version
      #    return # You're on the right version
      #  end
      #end
      alias_method_chain :current_version, :branches    
      def current_version_with_branches
        version_field = @@branch.blank? ? "version" : "version_#{@@branch}"
        sql = "SELECT #{version_field} FROM #{schema_info_table_name}"
        ( Base.connection.select_one( sql ) || { version_field => 0 } )[version_field].to_i
      end
    end

    alias_method_chain :initialize, :branches
    def initialize_with_branches( direction, migrations_path, target_version = nil, branch = nil )
      initialize_without_branches
      if branch.to_s.match /([a-zA-Z\-_0-9]+):?(?:([0-9]+))?/
        @@branch = $1
        @target_version = $2
      else
        @@branch = branch
      end

      unless branch.blank?
        begin
          version_field = (@@branch.nil? || @@branch.empty?) ? "version" : "version_#{@@branch}"
          Base.connection.execute( "ALTER TABLE #{ActiveRecord::Migrator.schema_info_table_name} ADD #{version_field} int(11) UNSIGNED DEFAULT 0;" )
        rescue ActiveRecord::StatementInvalid
          # Schema for branch has already been intialized
        end
      end
    end

    #def current_version( branch = nil )
    #  #@@branch = branch if branch.to_s.length > 0
    #  self.class.current_version( branch )
    #end

    # The whole purpose of overwriting this method was to be able to 
    # Inject the "In branch..." string, let's try to avoid overwriting 
    #methods we don't absolutely have to.

    #def migrate
    #  migration_classes.each do | ( version, migration_class ) |
    #    Base.logger.info( "Reached target version: #{@target_version}" ) and break if reached_target_version?( version )
    #    next if irrelevant_migration?( version )
    #
    #    Base.logger.info "Migrating to #{migration_class} (#{version})#{"In branch #{@@branch}" unless in_default_branch}"
    #    migration_class.migrate( @direction )
    #    set_schema_version( version )
    #  end
    #end

    private

    # This is essential to the branches logic
    # Let's attempt to use alias_method_chain insted of just plain hacking the method
    alias_method_chain :migration_files, :branches
    def migration_files_with_branches
      @migrations_base_path ||= @migrations_path
      if @@branch.to_s.length > 0
        @migrations_path += "#{@migrations_base_path}#{@@branch}/"
      end
      migration_files_without_branches
    end

    alias_method_chain :set_schema_version, :branches
    def set_schema_version_with_branches( version )
      unless @branch.blank?
        query =  "UPDATE #{self.class.schema_info_table_name} "
        query += "SET version_#{@@branch} = #{down? ? version.to_i - 1 : version.to_i}"
        Base.connection.update( query )
      else
        set_schema_version_without_branches
      end
    end

    #def migration_files
    #  files = Dir["#{@migrations_path}#{( "#{@@branch}/" ) if @@branch}[0-9]*_*.rb"]
    #  files.sort_by do | migration_file |
    #    migration_version_and_name( migration_file ).first.to_i
    #  end
    #  down? ? files.reverse : files
    #end

    #def in_default_branch
    #  @@branch.nil? || @@branch.empty? || @@branch == [ "default" ]
    #end
  end
end