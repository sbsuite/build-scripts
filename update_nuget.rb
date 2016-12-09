require 'FileUtils'
require_relative 'colorize'

def nuget_mirror(packages)
	nugetManager = NugetManager.new()
	nugetManager.MirrorPackages(packages);
	# nugetManager.PushInstalledPackages();
end

class NugetManager

	def PushInstalledPackages() 
		FileUtils.rm_rf("appveyor")
		FileUtils.rm_rf("nuget.org")
		InstallConfiguration("appveyor")
		InstallConfiguration("nuget.org")

		installedPackages = InstalledPackages("appveyor")

		installedPackages.select { |package| 
			MissingInSubdirectory(package, "nuget.org")
		}.each { |package| 
			DeployPackageFromDirectory(package, "appveyor")
		}
	end

	def InstalledPackages(subdir)
		return Dir.entries("./#{subdir}").select {|dir| dir != "." && dir != ".."}
	end

	def DeployPackageFromDirectory(package, directory)
		path = "#{directory}\\#{package}\\#{package}.nupkg"
		puts path
		cmd = "nuget.exe push #{path} -source nuget.org";
		system cmd
	end

	def MissingInSubdirectory(sourcePackage, subdir)
		!InstalledPackages(subdir).any?{ |package| package == sourcePackage}
	end

	def InstallConfiguration(feed)
		Dir.mkdir(feed)
		Dir.chdir(feed)
		cmd = "nuget.exe install ../packages.config -source #{feed} -nocache"
		system cmd
		Dir.chdir("..")
	end

	def MirrorPackages(packages)
		packages.select { |package|
			RequiresUpdate(package);
		}.each { |packageRequiringUpdate|
			DeployPackage(packageRequiringUpdate, "nuget.org")
		}
	end

	def RequiresUpdate(package)
		puts "Checking package #{package} for versions".green
		latestNugetVersion = GetLatestVersion(package, "nuget.org");
		latestFeedVersion = GetLatestVersion(package, "appveyor")
		
		return latestFeedVersion != latestNugetVersion
		
	end

	def DeployPackage(package, feed)
		puts "Deploying package #{package}".green
		InstallLatestVersion(package)
		directoryName = GetInstallDirectory(package);
		fileName = GetInstallDirectory(package) + ".nupkg";

		cmd = "nuget.exe push #{directoryName}\\#{fileName} -source #{feed}";

		system cmd
	end

	def GetLatestVersion(package, feed)
		listing = GetListingForPackage(package, feed);
		version = listing.find{|x| x.include? package }
		version.slice!(package+" ");
		puts "Version from #{feed} is #{version}".green;
		return version;
	end

	def GetListingForPackage(package, feed)
		cmd = "nuget.exe list " + package
		if(feed != nil)
			cmd = cmd + " -source " + feed
		end
		return `#{cmd}`.split("\n")
	end

	def GetInstallDirectory(package)
		return Dir[package+"*"][0];
	end

	def InstallLatestVersion(package)
		cmd = "nuget.exe install -nocache #{package}";
		print cmd;
		system cmd;
	end
end

nuget_mirror([
	"SBSuite.TestPackages.Package1.2",
	"SBSuite.TestPackages.Package1.1",
	"SBSuite.TestPackages.Package1.3",
	"SBSuite.TestPackages.Package2.1",
	"SBSuite.TestPackages.Package3.1",
	"SBSuite.build-scripts",
	"SBSuite.test-scripts",
	"SBSuite.setup-scripts"
]);