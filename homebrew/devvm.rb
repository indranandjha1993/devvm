class Devvm < Formula
  desc "Developer VM manager - multi-stack dev environment with observability"
  homepage "https://github.com/indranandjha1993/devvm"
  url "https://github.com/indranandjha1993/devvm/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "" # Will be filled after release
  license "MIT"
  version "2.2.0"

  depends_on "orbstack" => :optional

  def install
    # Install the CLI binary
    bin.install "cli/dev" => "devvm"

    # Install support files to share directory
    (share/"devvm").install "cloud-init"
    (share/"devvm").install "provision"
    (share/"devvm").install "observability"
    (share/"devvm").install "systemd"
    (share/"devvm").install "verify.sh"
    (share/"devvm").install "vscode"
    (share/"devvm").install "setup.sh"

    # Install shell completions
    bash_completion.install "completions/devvm.bash" => "devvm"
    zsh_completion.install "completions/_devvm"
  end

  def caveats
    <<~EOS
      OrbStack is required: https://orbstack.dev

      First time:
        devvm init        # Create the VM and install everything

      After every 'brew upgrade devvm':
        devvm upgrade     # Sync the VM with the new devvm version (non-destructive)

      Support files installed to: #{share}/devvm
    EOS
  end

  test do
    assert_match "devvm", shell_output("#{bin}/devvm version")
  end
end
