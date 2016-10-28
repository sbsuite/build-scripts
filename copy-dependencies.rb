require 'FileUtils'

#DSL to allow copying files defined under source_dir into target_dir
def copy_depdencies(source_dir, target_dir, &block)
	dependecyManager = DependencyManager.new(source_dir, target_dir)
	dependecyManager.instance_eval(&block)
	dependecyManager.perform_file_copy
end

class DependencyManager
	def initialize(source_dir, target_dir)
	  @source_dir = source_dir;
	  @target_dir = target_dir;
	end

	def dependencies
	  @dependencies ||= []
	end

	#copy files defined by file filters relative to source_dir
	#Example: 
	# => copy_file '**/native/*.dll'
	def copy_file(*filters)
		add_dep filters.map{|filter| File.join(@source_dir, filter)}
	end

	#copy files with file_extensions (either single or array)
	#Example: 
	# => copy_files 'native', ['dll', 'lib']
	# This call is equivalent to
	# => copy_file '**/native/*.dll'
	# => copy_file '**/native/*.lib'
	def copy_files(subfolder, file_extensions)
		retrieve_file_extensions(file_extensions) do |file_extension|
			copy_file File.join('**', subfolder, "*.#{file_extension}")
		end
	end

	#DSL internal method only called at the end of the copy_dependencies process
	#See http://ruby-doc.org/core-1.9.3/Dir.html#method-c-glob for glob documentation
	def perform_file_copy
		dependencies.each do |dep|
			Dir.glob(dep).each do |f| 
				puts "Copying #{f} to #{@target_dir}"
				FileUtils.copy f, @target_dir 
			end
		end
	end

	private 

	def add_dep(dependencies_to_add)
		dependencies_to_add.each {|dep| dependencies << dep}
	end

	def retrieve_file_extensions(file_extensions,&block)
	  if(file_extensions.respond_to? :each)
	    file_extensions.each(&block)
	  else
	    yield file_extensions
	  end
	end
end	