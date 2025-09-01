class Ignorer < Formula
  desc "Smart .gitignore generator - Generate .gitignore files from predefined templates"
  homepage "https://github.com/manucodin/ignorer"
  url "https://github.com/manucodin/ignorer/archive/v0.1.11.tar.gz"
  sha256 "c2014dacb7bf5b62d596b792e49cb15a281e4f31a71c3b0572e3a3e846d2746a"
  license "MIT"
  
  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w -X main.version=#{version}"), "./cmd/ignorer"
  end

  test do
    # Test that the binary runs and shows version
    assert_match version.to_s, shell_output("#{bin}/ignorer --version")
    
    # Test that list command works
    output = shell_output("#{bin}/ignorer list")
    assert_match "Available .gitignore templates:", output
    assert_match "Languages:", output
    
    # Test generating a gitignore file
    system "#{bin}/ignorer", "go"
    assert_predicate testpath/".gitignore", :exist?
  end
end 