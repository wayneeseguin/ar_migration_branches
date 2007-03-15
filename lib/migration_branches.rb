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

    attr_accessor :branch_name

    def initialize( branch_name )
      # Load the Rails environment
      @branch_name = branch_name
    end

    def yaml_path
      # #{RAILS_ROOT}/db/data/#{@branch_name}/#{@branch_name}.rb
    end

    def yaml_path
      # #{RAILS_ROOT}/db/data/#{@branch_name}/#{@branch_name}.rb
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

      def migrate( migrations_path, target_version = nil, branch = nil )
        @@branch = branch

        Base.connection.initialize_schema_information

        if @@branch.nil?
          Base.connection.initialize_schema_information
        else
          begin
            version_field = @@branch.nil? ? "version" : "version_#{@@branch}"
            Base.connection.execute( "ALTER TABLE `#{ActiveRecord::Migrator.schema_info_table_name}` ADD `#{version_field}` int(11) UNSIGNED DEFAULT '0';" )
            #Base.connection.execute( "INSERT INTO `#{ActiveRecord::Migrator.schema_info_table_name}` ( `#{version_field}` ) VALUES(0)" )
          rescue ActiveRecord::StatementInvalid
            # Schema for branch has already been intialized
          end
        end

        case
        when target_version.nil?, current_version < target_version
          up( migrations_path, target_version )
        when current_version > target_version
          down( migrations_path, target_version )
        when current_version == target_version
          return # You're on the right version
        end
      end

      def current_version( branch )
        @@branch = branch if branch.to_s.length > 0
        # changed
        version_field = (@@branch.nil? || @@branch.empty?) ? "version" : "version_#{@@branch}"
        sql = "SELECT `#{version_field}` FROM `#{schema_info_table_name}`"
        ( Base.connection.select_one( sql ) || {version_field => 0} )[version_field].to_i
      end
    end

    def initialize( direction, migrations_path, target_version = nil, branch = nil )
      # Changed
      raise StandardError.new( "This database does not yet support migrations" ) unless Base.connection.supports_migrations?
      @direction, @migrations_path, @target_version = direction, migrations_path, target_version

      @@branch ||= branch

      Base.connection.initialize_schema_information

      if @@branch.nil?
        Base.connection.initialize_schema_information
      else
        begin
          version_field = (@@branch.nil? || @@branch.empty?) ? "version" : "version_#{@@branch}"
          Base.connection.execute( "ALTER TABLE `#{ActiveRecord::Migrator.schema_info_table_name}` ADD `#{version_field}` int(11) UNSIGNED DEFAULT '0';" )
          #Base.connection.execute( "INSERT INTO `#{ActiveRecord::Migrator.schema_info_table_name}` ( `#{version_field}` ) VALUES(0)" )
        rescue ActiveRecord::StatementInvalid
          # Schema for branch has already been intialized
        end
      end
    end

    def current_version
      self.class.current_version
    end

    def migrate( branch = nil )
      # changed
      @@branch ||= branch
      migration_classes.each do | ( version, migration_class ) |
        Base.logger.info( "Reached target version: #{@target_version}" ) and break if reached_target_version?( version )
        next if irrelevant_migration?( version )

        Base.logger.info "Migrating to #{migration_class} (#{version})#{"In branch #{@@branch}" unless in_default_branch}"
        migration_class.migrate( @direction )
        set_schema_version( version )
      end
    end

    private

    def migration_files
      files = Dir["#{@migrations_path}#{( "#{@@branch}/" ) if @@branch}[0-9]*_*.rb"]
      files.sort_by do | migration_file |
        migration_version_and_name( migration_file ).first.to_i
      end
      down? ? files.reverse : files
    end

    def in_default_branch
      @@branch.nil? || @@branch.empty? || @@branch == [ "default" ]
    end
    
    def set_schema_version(version)
      version_field = (@@branch.nil? || @@branch.empty?) ? "version" : "version_#{@@branch}"
      Base.connection.update("UPDATE `#{self.class.schema_info_table_name}` SET `#{version_field}` = #{down? ? version.to_i - 1 : version.to_i}")
    end
    
  end
end