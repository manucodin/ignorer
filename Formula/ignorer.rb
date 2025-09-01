class Ignorer < Formula
  desc "Smart .gitignore generator - Generate .gitignore files from predefined templates"
  homepage "https://github.com/manucodin/ignorer"
  url "https://github.com/manucodin/ignorer/archive/v0.1.9.tar.gz"
  sha256 "106db9a2325f441707a0636af9e62186d9b4d5f2d0d7055e4e15c93e1fb1ef11"
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