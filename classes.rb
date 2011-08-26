require 'rake'
require 'fileutils'
require 'open5'

module Stamp
  def ts
    @stamp ||= Time.now.strftime("%Y%m%d%H%M")
  end
end

module Filez
  def copy(origin, destination)
    return false unless File.exists?(origin)
	
	#puts "destination[#{destination}] exists = " + File.exists?(destination).to_s
	FileUtils.mkdir_p(destination) unless File.exists?(destination)
	
    cmd = "xcopy \"#{origin}\\*\" \"#{destination}\" /S /Q /Y /Z"
	sh cmd
	true
  end
  
end

class SqlBackup
  include Stamp
  attr_accessor :server, :database, :path, :stamp, :username, :passwd, :file_name

  def initialize(server, database, path, user = 'sa', pwd = '1000Cracks')
    @server = server
	@database = database
	@path = path
	@username = user 
	@passwd = pwd 
	@file_name = "#{@server}.#{@database}_backup_#{self.ts}.bak"
  end
  
  def sql_cmd
    backup_query = "BACKUP DATABASE [#{@database}]"
    backup_query << " TO DISK = N'#{@path}#{@file_name}'"
    backup_query << " WITH NOFORMAT, NOINIT, NAME = N'#{@database}-Full Database Backup'"
    backup_query << ", SKIP, NOREWIND, NOUNLOAD, STATS = 10;"
	backup_query
  end
  
  def run_backup
    sqlcmd = 'sqlcmd -S ' + @server + ' -U '+@username+' -P '+@passwd+' -Q "'+self.sql_cmd + '"'
	sh sqlcmd
  end
end

class WebBackup
  include Stamp
  include Filez
  
  def backuppath(dest)
    dest + '-' + ts
  end
  
  def backup_old(origin, destination)
    return false if not File.exists?(origin)
    destination = backuppath(destination)
	#puts "origin=\t#{origin} \ndest=\t#{destination} \n\n"  
	begin
      copy origin, destination
	  true
	rescue Exception=>e
	  false
	end	
  end
  
  def backup(origin, destination)
    o = origin.gsub("\\",'/')  
    d = destination.gsub("\\",'/')
    archive = d+'/'+GLOBALCONFIG['project_name']+'-web-backup-'+Time.now.strftime("%Y%m%d%H%M")+'.zip'
    ZipIt.zip_folder archive, o
  end
end

class WebDeploy < WebBackup
  def deploy(origin, destination, backup)
    backup destination, backup #backup the current version
	copy origin, destination
	#webconf = backuppath(backup)+'\\web.config'
	#FileUtils.cp webconf, destination if File.exists?(webconf) # restore original web.config
	true
  end
end

class AppState
  attr_accessor :path, :htm_file
  
  def initialize(path)
    @path = path	
	@htm_file = File.dirname(__FILE__) + '/app_offline.htm'
  end
  
  def offline
    FileUtils.cp @htm_file, @path
  end
  
  def online
    FileUtils.mv(@path+'\app_offline.htm', @path+'\app_offline.off') if File.exists?(@path+'\app_offline.htm')
  end
end

class WebHost
  attr_accessor :path, :port, :clr, :usetray, :trace
  
  def initialize(path, port, clrversion = 'v3.5', usertray = false, trace = 'none')
    self.path = path
	self.port = port
	self.clr = clrversion
	self.usetray = usetray
	self.trace = trace
  end

  def start2()
	#$stdout.sync = true
	# |input, output, error, terminal??|
	open5('cmd', 'opt') {|i, o, e, t|
	  out = ''
	  while out != "\n"
		out = o.gets
		puts out
	  end
	  puts 'starting IIS Express...'
	  #i.puts 'startExpressBuild.bat'
	  #startCmd = IISEXP_CMD+' /path:c:\dev\tfs-vensure\realitycheck\deployed /port:10444 /clr:v3.5 /systray:true /trace:error'
	  startCmd = IISEXP_CMD+' /path:' + self.path + ' /port:'+self.port.to_s+' /clr:'+self.clr+' /systray:'+self.usetray.to_s+' /trace:'+self.trace
	  i.puts startCmd
	  
	  out = ''
	  while out != '\n' && out.match(/to stop IIS Express/)==nil
		out = o.gets
		puts out
		#puts out.match(/to stop IIS Express/)!=nil
	  end	  
	  Process.kill 'KILL', t.pid
	}
  end
  
  def start()
    system 'hstart /NOCONSOLE "startExpressBuild.bat ."'
  end

  def stop()
    puts 'killing all iis express instances...'
    `taskkill /F /im iisexpress.exe`
  end
end
