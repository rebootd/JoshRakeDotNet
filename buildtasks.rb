# ------------------------------------------------------------------------------------------------------
# AUTHOR: Josh Coffman
# PURPOSE: Automate deployment including backup of files and database
#
# DEPENDENCIES: run check-deps.bat to ensure Ruby 1.9.2 and required gems are installed. This bat file
#				will be run when you execute either of the deployment bat file to ensure it can complete
# ------------------------------------------------------------------------------------------------------

require 'rubygems'
require 'fileutils'
require 'albacore'
require File.dirname(__FILE__)+'/classes'
require File.dirname(__FILE__)+'/zipit'
require File.dirname(__FILE__)+'/env'
BUILDROOT = File.dirname(__FILE__)
GLOBALCONFIG = CONFIG['global']

nunit :test do |nunit|
  nunit.command = GLOBALCONFIG['nunit_cmd']
  nunit.assemblies GLOBALCONFIG['nunit_asm']
  nunit.options '/xml='+GLOBALCONFIG['nunit_output']
end

task :clean do
  FileUtils.rm_rf GLOBALCONFIG['output']
end

task :notimplemented do
  puts "\nnot implemented\n\n"
end

#---- build config ----#
#----------------------#
task :config_development do
  $buildconfig = CONFIG['development']
end
task :config_staging do
  $buildconfig = CONFIG['staging']
end
task :config_production do
  $buildconfig = CONFIG['production']
end
# default buildconfig
$buildconfig = CONFIG['development']

#---- util methods ----#
#----------------------#
def deployit(origin, dest, backup)
  puts 'starting deployment...'
  app = AppState.new(dest)
  app.offline
  puts 'deployment FAILED' and return false if not WebDeploy.new.deploy(origin, dest, backup)  
  app.online
  puts 'DONE'
  true
end

def backitup(source, backup)
  puts 'starting backup...'
  puts 'backup FAILED' and return false if not WebBackup.new.backup(source, backup)
  # compressit backup
  puts 'done'
  true
end

#---- compression  ----#
#----------------------#
def compressit(source)
  # compress file: ZipIt.zip_file "file.zip", file
  # compress folder: ZipIt.zip_folder "folder.zip", folder
end
task :zipweb => [:config_development] do
  backup_folder = File.expand_path(GLOBALCONFIG['output'])
  archive = $buildconfig['backup_web'] + GLOBALCONFIG['project_name'] + '-' + Time.now.strftime("%Y%m%d%H%M") + '.zip'
  ZipIt.zip_folder archive, backup_folder
end
task :zipsql => [:config_development] do
  # sql file = '#{@path}#{@server}.#{@database}_backup_#{self.ts}.bak'
  file = 'D:\dev\vesmerc\Spacely\build\Glimpse.Core.dll'
  archive = $buildconfig['backup_web'] + GLOBALCONFIG['project_name'] + '-' + Time.now.strftime("%Y%m%d%H%M") + '.zip'
  ZipIt.zip_file archive, file
end

#---- compile/build tasks ----#
#-----------------------------#
msbuild :build do |msb|
  msb.solution = GLOBALCONFIG['sln_file']
  msb.targets :clean, :build
  msb.properties :configuration => :debug, :outdir => ROOT+'/'+GLOBALCONFIG['output']
  msb.verbosity = 'quiet'
  if GLOBALCONFIG['msbuild_version'] != nil && GLOBALCONFIG['msbuild_version'] == 'v3.5'
    msb.command = 'C:\Windows\Microsoft.NET\Framework\v3.5\msbuild.exe'
	msb.parameters '/ToolsVersion:3.5'
  end
end

#---- sql backup tasks ----#
#--------------------------#
task :backup_sql do
  puts 'running sql backup..'
  backup = SqlBackup.new($buildconfig['dbserver'], $buildconfig['db'], $buildconfig['backup_sql'], $buildconfig['username'], $buildconfig['password'])
  backup.run_backup
  # now zip and cleanup
  file = $buildconfig['backup_sql_unc']+'/'+backup.file_name
  archive = file+'.zip'
  ZipIt.zip_file archive, file
  FileUtils.rm file
  puts 'complete.'
end

task :backup_dev_sql => [:config_development, :backup_sql]
task :backup_staging_sql => [:config_staging, :backup_sql]
task :backup_production_sql => [:config_production, :backup_sql]

#------ migration tasks ------#
#-----------------------------#
task :migrate_schema do
  schema_migration $buildconfig['migration_conn']
end

def schema_migration(connectionString)
  # execute Migration.exe with parameters
  migrateCmd = ROOT+'/'+GLOBALCONFIG['migration_cmd'] + ' -a ' + ROOT+'/'+GLOBALCONFIG['migration_asm'] + ' -db SqlServer2008 -conn "' + connectionString + '"'
  # puts migrateCmd
  $stdin.sync = true
  system migrateCmd
end

task :migrate_staging => [:config_staging, :migrate_schema]
task :migrate_prod => [:config_production, :migrate_schema]
