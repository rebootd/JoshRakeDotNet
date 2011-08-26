# gem 'rubyzip'
require 'zip/zipfilesystem'
require 'zip/zip'

class ZipIt
  
  def self.zip_file(archive, file)
    path = File.dirname(file)
    path.sub!(%r[/$],'')
    FileUtils.rm archive, :force=>true

	entry_name = File.basename(file) 
	Zip::ZipFile.open(archive, 'w') do |zipfile|    
      zipfile.add(entry_name,file)
    end
  end
  
  def self.zip_folder(archive, path)
    path.sub!(%r[/$],'')
    FileUtils.rm archive, :force=>true

	Zip::ZipFile.open(archive, 'w') do |zipfile|
      Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
	    zipfile.add(file.sub(path+'/',''),file)
      end
    end
  end

end
