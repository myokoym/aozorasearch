require_relative "../test_helper"
require "open3"

class SetupCodexAgentsTest < Minitest::Test
  REPO_ROOT = File.expand_path("../..", __dir__)
  SCRIPT_PATH = File.join(REPO_ROOT, "scripts", "setup-codex-agents.sh")

  def test_setup_installs_all_managed_agents_from_local_source
    Dir.mktmpdir("codex-agents-test-") do |dir|
      source_dir = create_source_repo(dir)
      destination_dir = File.join(dir, "agents")
      cache_dir = File.join(dir, "cache")

      stdout, stderr, status = run_setup(
        "AOZORASEARCH_CODEX_AGENT_SOURCE_URL" => source_dir,
        "AOZORASEARCH_CODEX_AGENT_CACHE_DIR" => cache_dir,
        "AOZORASEARCH_CODEX_AGENT_DEST_DIR" => destination_dir,
      )

      assert status.success?, stderr
      assert_match(/Installed #{managed_agent_files.size} managed agents/, stdout)

      installed_files = Dir.children(destination_dir).sort
      managed_manifest = File.join(destination_dir, ".aozorasearch-managed-agents")

      assert File.file?(managed_manifest)
      assert_equal(managed_agent_files.sort,
                   File.readlines(managed_manifest, chomp: true).reject(&:empty?).sort)
      assert_equal((managed_agent_files + [".aozorasearch-managed-agents"]).sort, installed_files)
    end
  end

  def test_setup_replaces_stale_managed_files_but_preserves_unmanaged_files
    Dir.mktmpdir("codex-agents-test-") do |dir|
      source_dir = create_source_repo(dir)
      destination_dir = File.join(dir, "agents")
      cache_dir = File.join(dir, "cache")
      FileUtils.mkdir_p(destination_dir)
      File.write(File.join(destination_dir, "custom-agent.toml"), "name = \"custom-agent\"\n")
      File.write(File.join(destination_dir, "obsolete-agent.toml"), "name = \"obsolete-agent\"\n")
      File.write(File.join(destination_dir, ".aozorasearch-managed-agents"), "obsolete-agent.toml\n")

      _stdout, stderr, status = run_setup(
        "AOZORASEARCH_CODEX_AGENT_SOURCE_URL" => source_dir,
        "AOZORASEARCH_CODEX_AGENT_CACHE_DIR" => cache_dir,
        "AOZORASEARCH_CODEX_AGENT_DEST_DIR" => destination_dir,
      )

      assert status.success?, stderr
      refute File.exist?(File.join(destination_dir, "obsolete-agent.toml"))
      assert File.exist?(File.join(destination_dir, "custom-agent.toml"))
      assert File.exist?(File.join(destination_dir, "ui-designer.toml"))
      assert File.exist?(File.join(destination_dir, "security-auditor.toml"))
    end
  end

  private

  def create_source_repo(base_dir)
    source_dir = File.join(base_dir, "source")
    FileUtils.mkdir_p(source_dir)

    managed_agent_paths.each do |relative_path|
      full_path = File.join(source_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(full_path))
      agent_name = File.basename(relative_path, ".toml")
      File.write(full_path, <<~TOML)
        name = "#{agent_name}"
        description = "fixture"
      TOML
    end

    run_command("git", "init", "-q", chdir: source_dir)
    run_command("git", "config", "user.name", "Test User", chdir: source_dir)
    run_command("git", "config", "user.email", "test@example.com", chdir: source_dir)
    run_command("git", "add", ".", chdir: source_dir)
    run_command("git", "commit", "-qm", "fixture", chdir: source_dir)

    source_dir
  end

  def run_setup(extra_env)
    Open3.capture3(
      {
        "BUNDLE_GEMFILE" => File.join(REPO_ROOT, "Gemfile"),
      }.merge(extra_env),
      "bash",
      SCRIPT_PATH,
      chdir: REPO_ROOT,
    )
  end

  def run_command(*command, chdir:)
    _stdout, stderr, status = Open3.capture3(*command, chdir: chdir)
    assert status.success?, stderr
  end

  def managed_agent_files
    @managed_agent_files ||= managed_agent_paths.map { |path| File.basename(path) }.freeze
  end

  def managed_agent_paths
    @managed_agent_paths ||= begin
      script_content = File.read(SCRIPT_PATH)
      paths_string = script_content.match(/managed_agent_paths=\(\s*([^)]+)\s*\)/m)&.captures&.first || ""
      paths_string.scan(/"([^"]+)"/).flatten.freeze
    end
  end
end
