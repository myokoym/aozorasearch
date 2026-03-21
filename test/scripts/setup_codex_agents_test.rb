require_relative "../test_helper"
require "open3"

class SetupCodexAgentsTest < Minitest::Test
  REPO_ROOT = File.expand_path("../..", __dir__)
  SCRIPT_PATH = File.join(REPO_ROOT, "scripts", "setup-codex-agents.sh")
  MANAGED_AGENT_PATHS = %w[
    categories/01-core-development/api-designer.toml
    categories/01-core-development/backend-developer.toml
    categories/01-core-development/code-mapper.toml
    categories/01-core-development/frontend-developer.toml
    categories/01-core-development/fullstack-developer.toml
    categories/01-core-development/ui-designer.toml
    categories/01-core-development/ui-fixer.toml
    categories/03-infrastructure/database-administrator.toml
    categories/03-infrastructure/deployment-engineer.toml
    categories/03-infrastructure/devops-engineer.toml
    categories/03-infrastructure/security-engineer.toml
    categories/03-infrastructure/sre-engineer.toml
    categories/04-quality-security/accessibility-tester.toml
    categories/04-quality-security/architect-reviewer.toml
    categories/04-quality-security/browser-debugger.toml
    categories/04-quality-security/code-reviewer.toml
    categories/04-quality-security/debugger.toml
    categories/04-quality-security/error-detective.toml
    categories/04-quality-security/performance-engineer.toml
    categories/04-quality-security/qa-expert.toml
    categories/04-quality-security/reviewer.toml
    categories/04-quality-security/security-auditor.toml
    categories/04-quality-security/test-automator.toml
    categories/06-developer-experience/build-engineer.toml
    categories/06-developer-experience/cli-developer.toml
    categories/06-developer-experience/dependency-manager.toml
    categories/06-developer-experience/documentation-engineer.toml
    categories/06-developer-experience/dx-optimizer.toml
    categories/06-developer-experience/git-workflow-manager.toml
    categories/06-developer-experience/legacy-modernizer.toml
    categories/06-developer-experience/refactoring-specialist.toml
    categories/06-developer-experience/tooling-engineer.toml
    categories/10-research-analysis/docs-researcher.toml
    categories/10-research-analysis/search-specialist.toml
  ].freeze
  MANAGED_AGENT_FILES = MANAGED_AGENT_PATHS.map { |path| File.basename(path) }.freeze

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
      assert_match(/Installed #{MANAGED_AGENT_FILES.size} managed agents/, stdout)

      installed_files = Dir.children(destination_dir).sort
      managed_manifest = File.join(destination_dir, ".aozorasearch-managed-agents")

      assert File.file?(managed_manifest)
      assert_equal(MANAGED_AGENT_FILES.sort,
                   File.readlines(managed_manifest, chomp: true).reject(&:empty?).sort)
      assert_equal((MANAGED_AGENT_FILES + [".aozorasearch-managed-agents"]).sort, installed_files)
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

    MANAGED_AGENT_PATHS.each do |relative_path|
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
end
