# ------------------------------------------------------------------------------------------------------
# AUTHOR: Josh Coffman
# PURPOSE: rakefile for example project
# ------------------------------------------------------------------------------------------------------
require 'yaml'
require 'fileutils'
ROOT = File.dirname(__FILE__)
CONFIG = YAML::load_file(ROOT+'/rakeconfig.yml') unless defined? CONFIG
JENKINSDIR = 'd:\jenkins\jobs\BuildTools\workspace'
if Dir.exists? JENKINSDIR
  require JENKINSDIR+'\buildtasks'
else
  require CONFIG['global']['buildenv']+'buildtasks'
end

# stagedeploy, migrate_staging
task :stagedeploy => [:config_staging, :clean, :build, :backup_sql, :deploy_stage_web]
task :deploy_stage_web do
  # deployit ROOT+'/'+GLOBALCONFIG['output'], $buildconfig['destination'], $buildconfig['backup_web']
  deployit ROOT+'/'+GLOBALCONFIG['output']+'/_PublishedWebsites/example', $buildconfig['destination'], $buildconfig['backup_web']
end

# proddeploy, migrate_prod
task :proddeploy => [:config_production, :backup_sql, :deploy_prod_web]
task :deploy_prod_web do
  # deployit STAGE_DEST, PROD_DEST, PROD_BACKUP  
  deployit CONFIG['staging']['destination'], $buildconfig['destination'], $buildconfig['backup_web']
end
