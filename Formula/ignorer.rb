class Ignorer < Formula
  desc "Smart .gitignore generator - Generate .gitignore files from predefined templates"
  homepage "https://github.com/manucodin/ignorer"
  url "https://github.com/manucodin/ignorer/archive/v0.1.6.tar.gz"
  sha256 "5a00134708db95c9291e7053c43e82be64ca434a25cce03342c62547eaaafada"
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