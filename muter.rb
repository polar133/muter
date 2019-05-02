class Muter_TEST < Formula
	desc "Automated mutation testing for Swift"
	homepage "https://github.com/polar133/muter"
	url "https://github.com/polar133/muter", :using => GitHubPrivateRepositoryReleaseDownloadStrategy
    head "https://github.com/polar133/muter.git"
	
	def install
		system "make", "install", "prefix=#{prefix}"
	end

end
