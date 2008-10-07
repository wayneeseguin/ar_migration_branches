# Copyright (c) 2006-Present Wayne E. Seguin
# 
# THIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module ActiveRecord

  class Migrator #:nodoc:
    class << self

      attr_accessor :branch
      attr_accessor :target_version
      
      # Modify to retrieve for branches
      def current_version
        branch = ActiveRecord::Migrator.branch
        sql = "SELECT version FROM #{schema_migrations_table_name}"
        sql << " WHERE version like '%_#{branch}'" if branch
        Base.connection.select_values(sql).map(&:to_i).max rescue 0
      end
    end
    
    def migrated
      sm_table = self.class.schema_migrations_table_name
      branch = ActiveRecord::Migrator.branch
      sql = "SELECT version FROM #{sm_table}"
      sql << " WHERE version like '%_#{branch}'" if branch
      Base.connection.select_values(sql).map(&:to_i).sort
    end

    private
    
    def record_version_state_after_migrating(version)
      sm_table = self.class.schema_migrations_table_name
      branch = ActiveRecord::Migrator.branch
      if down?
        Base.connection.update("DELETE FROM #{sm_table} WHERE version = '#{branch ? "#{version}_#{branch}" : version}'")
      else
        Base.connection.insert("INSERT INTO #{sm_table} (version) VALUES ('#{version}_#{branch}')")
      end
    end

  end # end class Migrator
end # end module ActiveRecord
