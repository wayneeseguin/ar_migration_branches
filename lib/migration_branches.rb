# Copyright (c) 2006-Present Wayne E. Seguin
# 
# THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class String
  def log( type = nil )
    case type
    when :info
      puts "<i> #{self}"
    when :error
      puts "!! #{self}"
    when :debug
      puts "<b> #{self}" if ENV["DEBUG"] == "true"
    when :inspect
      puts "  - #{self}" if ENV["DEBUG"] == "true"
    when :method
      puts "() #{self}" if ENV["DEBUG"] == "true"
    when :header, :footer
      puts "===============================================================================\n"      
      puts "= #{self}"
      puts "===============================================================================\n"      
    else # :log is default
      puts "#{self}"
    end
  end
end

module ActiveRecord

  class Migrator#:nodoc:
    class << self

      attr_accessor :branch
      attr_accessor :target_version

      def current_version_with_branches
        "current_version_with_branches".log( :method )
        version_field = ActiveRecord::Migrator.branch.blank? ? "version" : "version_#{ActiveRecord::Migrator.branch}"
        sql = "SELECT #{version_field} FROM #{schema_info_table_name}"
        begin
          current_version = ( Base.connection.select_one( sql ) || { version_field => 0 } )[version_field].to_i
        rescue ActiveRecord::StatementInvalid
          "selecting version field failed, setting current version to 0".log( :error )
          current_version = 0
        end
        "current version selected: #{current_version}".log
        current_version || 0
      end
      alias_method_chain :current_version, :branches
    end
    
    def self.initialize_branch_schema
      "self.initialize_schema_information_with_branches".log( :method )
      "branch: #{ActiveRecord::Migrator.branch}".log( :inspect )
      
      version_field = ActiveRecord::Migrator.branch.blank? ? "version" : "version_#{ActiveRecord::Migrator.branch}"
      begin
        Base.connection.initialize_schema_information
        Base.connection.execute( "ALTER TABLE #{ActiveRecord::Migrator.schema_info_table_name} ADD #{version_field} int(11) UNSIGNED DEFAULT 0;" )
        "Added schema_info.#{version_field}".log :info
      rescue ActiveRecord::StatementInvalid
        "schema_info.#{version_field} already exists".log :error
      end
    end

    private
    
    def extract_branch( branch_name = nil )
      "extract_branch".log( :method ) and "branch_name: #{branch_name}".log( :inspect )
      
      if branch_name.to_s.match( /([a-zA-Z\-_0-9]+):?(?:([0-9]+))?/ )
        return $1, $2
      else
        return branch_name, nil
      end
    end
    
    def set_schema_version_with_branches( version )
      "set_schema_version_with_branches".log :method
      "version: #{version} ; branch: #{ActiveRecord::Migrator.branch}".log :inspect
      
      unless ActiveRecord::Migrator.branch.blank?
        query = <<-QUERY
        UPDATE #{ActiveRecord::Migrator.schema_info_table_name} SET
        version_#{ActiveRecord::Migrator.branch} = #{down? ? version.to_i - 1 : version.to_i}
        QUERY
        Base.connection.update( query )
      else
        set_schema_version_without_branches( version )
      end
    end
    alias_method_chain :set_schema_version, :branches

  end # end class Migrator
end # end module ActiveRecord

# MigrationBranches Ruby on Rails Plugin
#module MigrationBranches
##  extend Tracer
#  class DataLoader
#
#    attr_accessor :branch
#
#    def initialize( branch_name = nil )
#      # Load the Rails environment
#      # ActiveRecord::Migrator.branch = branch_name
#    end
#
#    def yaml_path
#      # #{RAILS_ROOT}/db/data/#{ActiveRecord::Migrator.branch}/#{ActiveRecord::Migrator.branch}.rb
#    end
#
#    # Create records in join table given human readable field mapping and
#    # both sides of join.
#    # EXAMPLE:
#    # branch_name: "assessment_question"
#    # parent_class: Assessment
#    # child_class: Question
#    # join_class: AssessmentQuestion
#    # map_field: "Question"
#    # child_attribute: "code_name"
#    #
#    # load_join_table_data( 
#    #   :file_name => "db/data/", 
#    #   :parent => "Assessment", 
#    #   :child => "Question", 
#    #   :map_field => "Question", 
#    #   :child_attribute => )
#
#    def load_join_table_data_from_file( join_file_name )
#      join_file_name.match
#      parent = $1
#      child = $2
#      # parse file name to get parent and child class names
#      # load file and get map_field, child_attribute
#      self.load_join_table_data( options )
#    end
#
#    def load_join_table_data( options = { } )
#      parent_class.find( :all ).each do | parent |
#        begin
#          # clear out the old mappings
#          parent.send( join_class.name.underscore.pluralize ).destroy_all unless parent.send( join_class.class.name.underscore).empty?
#
#          # load this parent's children from the yml file
#          unless File.zero?( self.yaml_path )
#            yaml = YAML.load( File.read( self.yaml_path ) ).each do | data |
#              # create a new join record
#              child_record = child_class.send( "find_by_#{child_attribute}( data['#{map_field}'] )" )
#              new_join_record = parent.send( join_class.class.name.underscore ).new( data )
#              new_join_record.send( child_class.class.name.underscore )# = child_record # What was the intent here?
#              new_join_record.save
#            end
#          else
#            # no join file, which should be impossible
#          end
#        rescue
#          puts("Problem loading join data from #{self.yaml_path}: #{$!}")
#        end
#      end    
#    end
#  end
#end
